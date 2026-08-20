'use strict';

const assert = require('assert');
const { HttpsError } = require('firebase-functions/v2/https');
const { MemoryFirestore } = require('./memory_firestore');
const {
  normalizeCountryCode,
  normalizeCitySlug,
} = require('../src/home_geography');
const {
  SCHEMA_VERSION,
  PUBLIC_GET_KEYS,
  passportPath,
  handleGetDiscoverPassport,
  handleSetDiscoverPassport,
  handleDisableDiscoverPassport,
} = require('../src/discover_passport_callable');

function request(uid, data = {}) {
  return {
    auth: uid ? { uid } : null,
    data,
  };
}

function deps(db) {
  return { db, serverTimestamp: () => 'TS' };
}

async function seedEntitlement(db, uid, raw) {
  await db.doc(`entitlements/${uid}`).set({
    uid,
    ...raw,
  });
}

describe('home_geography JS port', () => {
  it('Turkish display city normalizes to istanbul slug', () => {
    assert.strictEqual(normalizeCountryCode('tr'), 'TR');
    assert.strictEqual(normalizeCitySlug('İstanbul'), 'istanbul');
    assert.strictEqual(normalizeCitySlug('ISTANBUL'), 'istanbul');
    assert.strictEqual(normalizeCitySlug('München'), 'munchen');
    assert.strictEqual(normalizeCitySlug('New York'), 'new-york');
  });

  it('rejects unsafe or empty country/city', () => {
    assert.strictEqual(normalizeCountryCode('TUR'), null);
    assert.strictEqual(normalizeCountryCode(''), null);
    assert.strictEqual(normalizeCitySlug(''), null);
    assert.strictEqual(normalizeCitySlug('???'), null);
  });
});

describe('discover passport callables', () => {
  it('unauthenticated throws', async () => {
    const db = new MemoryFirestore();
    await assert.rejects(
      () => handleGetDiscoverPassport(request(null), deps(db)),
      (err) => err instanceof HttpsError && err.code === 'unauthenticated',
    );
    await assert.rejects(
      () =>
        handleSetDiscoverPassport(
          request(null, { passport_country: 'TR', passport_city: 'istanbul' }),
          deps(db),
        ),
      (err) => err instanceof HttpsError && err.code === 'unauthenticated',
    );
    await assert.rejects(
      () => handleDisableDiscoverPassport(request(null), deps(db)),
      (err) => err instanceof HttpsError && err.code === 'unauthenticated',
    );
  });

  it('Free cannot enable Passport', async () => {
    const db = new MemoryFirestore();
    await seedEntitlement(db, 'free', {
      tier: 'free',
      subscription_state: 'none',
    });
    await assert.rejects(
      () =>
        handleSetDiscoverPassport(
          request('free', {
            passport_country: 'TR',
            passport_city: 'istanbul',
          }),
          deps(db),
        ),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'failed-precondition' &&
        err.details &&
        err.details.code === 'resonance_required',
    );
    const snap = await db.doc(passportPath('free')).get();
    assert.strictEqual(snap.exists, false);
  });

  it('Free cannot change destination', async () => {
    const db = new MemoryFirestore();
    await seedEntitlement(db, 'free', {
      tier: 'free',
      subscription_state: 'none',
    });
    await db.doc(passportPath('free')).set({
      passport_enabled: true,
      passport_country: 'TR',
      passport_city: 'istanbul',
      schema_version: SCHEMA_VERSION,
    });
    await assert.rejects(
      () =>
        handleSetDiscoverPassport(
          request('free', { passport_country: 'DE', passport_city: 'berlin' }),
          deps(db),
        ),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'failed-precondition' &&
        err.details.code === 'resonance_required',
    );
    const snap = await db.doc(passportPath('free')).get();
    assert.strictEqual(snap.data().passport_city, 'istanbul');
  });

  it('Resonance can enable and set one destination', async () => {
    const db = new MemoryFirestore();
    await seedEntitlement(db, 'paid', {
      tier: 'resonance',
      subscription_state: 'active',
    });
    const res = await handleSetDiscoverPassport(
      request('paid', { passport_country: 'tr', passport_city: 'İstanbul' }),
      deps(db),
    );
    assert.deepStrictEqual(res, {
      resonance_access: true,
      passport_enabled: true,
      passport_country: 'TR',
      passport_city: 'istanbul',
    });
    const snap = await db.doc(passportPath('paid')).get();
    const data = snap.data();
    assert.strictEqual(data.passport_enabled, true);
    assert.strictEqual(data.passport_country, 'TR');
    assert.strictEqual(data.passport_city, 'istanbul');
    assert.strictEqual(data.schema_version, SCHEMA_VERSION);
    assert.strictEqual(data.updated_at, 'TS');
    assert.strictEqual(data.geohash, undefined);
    assert.strictEqual(data.latitude, undefined);
    assert.strictEqual(data.longitude, undefined);
    assert.strictEqual(data.location, undefined);
    assert.strictEqual(data.home_city, undefined);
    assert.strictEqual(data.resonance_access, undefined);
    assert.strictEqual(data.super_resonance_balance, undefined);
  });

  it('ignores forged resonance_access in the request', async () => {
    const db = new MemoryFirestore();
    await seedEntitlement(db, 'free', {
      tier: 'free',
      subscription_state: 'none',
      resonance_access: true,
    });
    await assert.rejects(
      () =>
        handleSetDiscoverPassport(
          request('free', {
            resonance_access: true,
            passport_country: 'TR',
            passport_city: 'istanbul',
          }),
          deps(db),
        ),
      (err) =>
        err instanceof HttpsError &&
        err.details &&
        err.details.code === 'resonance_required',
    );
  });

  it('expired or revoked Resonance is effective OFF on get', async () => {
    const db = new MemoryFirestore();
    await seedEntitlement(db, 'paid', {
      tier: 'resonance',
      subscription_state: 'expired',
    });
    await db.doc(passportPath('paid')).set({
      passport_enabled: true,
      passport_country: 'GB',
      passport_city: 'london',
      schema_version: SCHEMA_VERSION,
    });
    const expired = await handleGetDiscoverPassport(
      request('paid'),
      deps(db),
    );
    assert.deepStrictEqual(expired, {
      resonance_access: false,
      passport_enabled: false,
      passport_country: 'GB',
      passport_city: 'london',
    });
    for (const key of Object.keys(expired)) {
      assert.ok(PUBLIC_GET_KEYS.includes(key), key);
    }

    await seedEntitlement(db, 'paid', {
      tier: 'resonance',
      subscription_state: 'revoked',
    });
    const revoked = await handleGetDiscoverPassport(
      request('paid'),
      deps(db),
    );
    assert.strictEqual(revoked.passport_enabled, false);
    assert.strictEqual(revoked.passport_country, 'GB');
  });

  it('disable works for Free and keeps saved destination', async () => {
    const db = new MemoryFirestore();
    await seedEntitlement(db, 'free', {
      tier: 'free',
      subscription_state: 'none',
    });
    await db.doc('users/free').set({
      location: { latitude: 41.0, longitude: 29.0 },
      location_text: 'Kadıköy, İstanbul',
      home_country: 'TR',
      home_city: 'istanbul',
    });
    await db.doc(passportPath('free')).set({
      passport_enabled: true,
      passport_country: 'DE',
      passport_city: 'berlin',
      schema_version: SCHEMA_VERSION,
    });
    const res = await handleDisableDiscoverPassport(
      request('free'),
      deps(db),
    );
    assert.deepStrictEqual(res, {
      resonance_access: false,
      passport_enabled: false,
      passport_country: 'DE',
      passport_city: 'berlin',
    });
    const user = (await db.doc('users/free').get()).data();
    assert.deepStrictEqual(user.location, { latitude: 41.0, longitude: 29.0 });
    assert.strictEqual(user.location_text, 'Kadıköy, İstanbul');
    assert.strictEqual(user.home_country, 'TR');
    assert.strictEqual(user.home_city, 'istanbul');
  });

  it('rejects invalid city/country', async () => {
    const db = new MemoryFirestore();
    await seedEntitlement(db, 'paid', {
      tier: 'resonance',
      subscription_state: 'active',
    });
    await assert.rejects(
      () =>
        handleSetDiscoverPassport(
          request('paid', { passport_country: 'TUR', passport_city: 'istanbul' }),
          deps(db),
        ),
      (err) => err instanceof HttpsError && err.code === 'invalid-argument',
    );
    await assert.rejects(
      () =>
        handleSetDiscoverPassport(
          request('paid', { passport_country: 'TR', passport_city: '' }),
          deps(db),
        ),
      (err) => err instanceof HttpsError && err.code === 'invalid-argument',
    );
    await assert.rejects(
      () =>
        handleSetDiscoverPassport(
          request('paid', { passport_country: 'TR', passport_city: '???' }),
          deps(db),
        ),
      (err) => err instanceof HttpsError && err.code === 'invalid-argument',
    );
  });

  it('get returns public keys only and empty defaults', async () => {
    const db = new MemoryFirestore();
    const res = await handleGetDiscoverPassport(request('n1'), deps(db));
    assert.deepStrictEqual(Object.keys(res).sort(), [...PUBLIC_GET_KEYS].sort());
    assert.deepStrictEqual(res, {
      resonance_access: false,
      passport_enabled: false,
      passport_country: null,
      passport_city: null,
    });
    const blob = JSON.stringify(res);
    assert.strictEqual(blob.includes('latitude'), false);
    assert.strictEqual(blob.includes('geohash'), false);
    assert.strictEqual(blob.includes('super_resonance'), false);
  });

  it('set overwrites to a single destination', async () => {
    const db = new MemoryFirestore();
    await seedEntitlement(db, 'paid', {
      tier: 'resonance',
      subscription_state: 'active',
    });
    await handleSetDiscoverPassport(
      request('paid', { passport_country: 'TR', passport_city: 'istanbul' }),
      deps(db),
    );
    const res = await handleSetDiscoverPassport(
      request('paid', { passport_country: 'GB', passport_city: 'london' }),
      deps(db),
    );
    assert.strictEqual(res.passport_country, 'GB');
    assert.strictEqual(res.passport_city, 'london');
    const data = (await db.doc(passportPath('paid')).get()).data();
    assert.strictEqual(data.passport_country, 'GB');
    assert.strictEqual(data.passport_city, 'london');
  });

  it('does not touch Discover L2 callable or user location on set', async () => {
    const db = new MemoryFirestore();
    await seedEntitlement(db, 'paid', {
      tier: 'resonance',
      subscription_state: 'active',
    });
    await db.doc('users/paid').set({
      location: { latitude: 1, longitude: 2 },
      location_text: 'home text',
      home_country: 'TR',
      home_city: 'istanbul',
    });
    await handleSetDiscoverPassport(
      request('paid', { passport_country: 'DE', passport_city: 'berlin' }),
      deps(db),
    );
    const user = (await db.doc('users/paid').get()).data();
    assert.strictEqual(user.location_text, 'home text');
    assert.strictEqual(user.home_city, 'istanbul');
    const fs = require('fs');
    const path = require('path');
    const l2 = fs.readFileSync(
      path.resolve(__dirname, '../src/stage_b2_l2_callable.js'),
      'utf8',
    );
    assert.strictEqual(l2.includes('passport'), false);
    const discover = fs.readFileSync(
      path.resolve(__dirname, '../../lib/features/discover/services/discover_service.dart'),
      'utf8',
    );
    assert.ok(discover.includes("where('discover_eligible', isEqualTo: true)"));
    assert.ok(discover.includes("where('home_country'"));
    assert.ok(discover.includes("where('home_city'"));
    assert.ok(discover.includes('plan.usesDestinationFilter'));
    assert.ok(discover.includes('plan.skipEligibleQuery'));
    assert.strictEqual(discover.includes("where('passport_"), false);
  });
});
