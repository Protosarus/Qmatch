'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { MemoryFirestore } = require('./memory_firestore');
const {
  REGION,
  USER_DOCUMENT_PATH,
  PUBLIC_PROFILES_COLLECTION,
  PUBLIC_PROFILE_KEYS,
  buildPublicProfileProjection,
  handlePublicProfileUserWritten,
} = require('../src/public_profiles_projection');

const FORBIDDEN_KEYS = Object.freeze([
  'email',
  'phone_number',
  'auth_provider',
  'gender',
  'looking_for',
  'archetype',
  'category',
  'iq_normalized',
  'eq_normalized',
  'iq_score',
  'eq_score',
  'frequency_type',
  'frequency_score',
  'frequency_tags',
  'frequency_vector',
  'vector',
  'last_active_at',
  'active',
  'profile_completed',
  'test_completed',
  'assessment_flow_completed',
  'location',
  'location_text',
  'age_range',
  'distance_preference',
  'account_deletion_requested',
  'account_deletion_requested_at',
  'compat',
  'compatibility_score',
]);

function privateUser(overrides = {}) {
  return {
    uid: 'userA',
    email: 'secret@example.com',
    phone_number: '+15555550100',
    auth_provider: 'phone',
    name: 'Ada',
    age: 29,
    bio: 'Hello',
    gender: 'female',
    looking_for: 'everyone',
    occupation: 'Engineer',
    company: 'Acme',
    education: 'University',
    school: 'MIT',
    education_field: 'CS',
    anthem_title: 'Helplessness Blues',
    anthem_artist: 'Fleet Foxes',
    interests: ['music', '  ', 12, 'hiking'],
    photos: ['https://example.com/a.jpg', '  ', null],
    profile_photo_url: 'https://example.com/a.jpg',
    home_country: 'TR',
    home_city: 'istanbul',
    archetype: 'The Realist',
    category: 'MM',
    iq_normalized: 88,
    eq_normalized: 71,
    frequency_type: 'Deep Connector',
    frequency_score: 0.9,
    frequency_tags: ['secret'],
    frequency_vector: { depth: 0.8 },
    vector: { depth: 0.8 },
    last_active_at: '2026-08-28T00:00:00.000Z',
    active: true,
    profile_completed: true,
    test_completed: true,
    assessment_flow_completed: true,
    location: { latitude: 41.0, longitude: 29.0 },
    location_text: 'Istanbul',
    age_range: [25, 35],
    distance_preference: 50,
    account_deletion_requested: false,
    discover_eligible: true,
    ...overrides,
  };
}

function snapshot(data, exists) {
  return {
    exists,
    data: () => (exists ? data : undefined),
  };
}

function writtenEvent({
  uid = 'userA',
  before,
  after,
  beforeExists,
  afterExists,
} = {}) {
  const afterOn = afterExists ?? after != null;
  const beforeOn = beforeExists ?? before != null;
  return {
    params: { uid },
    data: {
      before: snapshot(before, beforeOn),
      after: snapshot(after, afterOn),
    },
  };
}

function publicDoc(db, uid = 'userA') {
  return db.doc(`${PUBLIC_PROFILES_COLLECTION}/${uid}`);
}

function userStoreKeys(db) {
  return [...db._store.keys()].filter((key) => key.startsWith('users/'));
}

describe('public_profiles projection', () => {
  it('exports europe-west1 users/{uid} constants and the full whitelist', () => {
    assert.strictEqual(REGION, 'europe-west1');
    assert.strictEqual(USER_DOCUMENT_PATH, 'users/{uid}');
    assert.deepStrictEqual([...PUBLIC_PROFILE_KEYS], [
      'discover_eligible',
      'home_country',
      'home_city',
      'name',
      'age',
      'bio',
      'photos',
      'profile_photo_url',
      'occupation',
      'company',
      'education',
      'school',
      'education_field',
      'anthem_title',
      'anthem_artist',
      'interests',
    ]);
  });

  it('index.js wires a single europe-west1 export and no US twin', () => {
    const indexSrc = fs.readFileSync(
      path.join(__dirname, '../index.js'),
      'utf8',
    );
    assert.ok(indexSrc.includes('exports.syncPublicProfileOnUserWrite'));
    assert.ok(indexSrc.includes('public_profiles_projection'));
    assert.ok(!indexSrc.includes('syncPublicProfileOnUserWriteEu'));
    const projectionBlock = indexSrc.slice(
      indexSrc.indexOf('exports.syncPublicProfileOnUserWrite'),
      indexSrc.indexOf('exports.handlePublicProfileUserWritten'),
    );
    assert.ok(projectionBlock.includes("region: 'europe-west1'"));
    assert.ok(!projectionBlock.includes('us-central1'));
  });

  it('projection source never merges and never writes users/{uid}', () => {
    const src = fs.readFileSync(
      path.join(__dirname, '../src/public_profiles_projection.js'),
      'utf8',
    );
    assert.ok(!src.includes('merge: true'));
    assert.ok(!src.includes('merge:true'));
    assert.ok(!src.includes('SetOptions'));
    assert.ok(!src.includes('deriveDiscoverEligible'));
    assert.ok(src.includes('await ref.set(projection);'));
    assert.ok(!/db\.doc\(`users\//.test(src));
    assert.ok(!/collection\('users'\)/.test(src));
  });

  it('copies allowed fields and never copies private/forbidden fields', () => {
    const projected = buildPublicProfileProjection(privateUser());
    assert.strictEqual(projected.discover_eligible, true);
    assert.strictEqual(projected.name, 'Ada');
    assert.strictEqual(projected.age, 29);
    assert.strictEqual(projected.bio, 'Hello');
    assert.strictEqual(projected.occupation, 'Engineer');
    assert.strictEqual(projected.company, 'Acme');
    assert.strictEqual(projected.education, 'University');
    assert.strictEqual(projected.school, 'MIT');
    assert.strictEqual(projected.education_field, 'CS');
    assert.strictEqual(projected.anthem_title, 'Helplessness Blues');
    assert.strictEqual(projected.anthem_artist, 'Fleet Foxes');
    assert.deepStrictEqual(projected.photos, ['https://example.com/a.jpg']);
    assert.strictEqual(projected.profile_photo_url, 'https://example.com/a.jpg');
    assert.deepStrictEqual(projected.interests, ['music', 'hiking']);
    assert.strictEqual(projected.home_country, 'TR');
    assert.strictEqual(projected.home_city, 'istanbul');

    for (const key of Object.keys(projected)) {
      assert.ok(
        PUBLIC_PROFILE_KEYS.includes(key),
        `unexpected public key ${key}`,
      );
    }
    for (const key of FORBIDDEN_KEYS) {
      assert.ok(!(key in projected), `leaked ${key}`);
    }
  });

  it('copies stored discover_eligible and defaults non-booleans to false', () => {
    assert.strictEqual(
      buildPublicProfileProjection({
        profile_completed: true,
        test_completed: true,
        assessment_flow_completed: true,
        active: true,
        photos: ['https://example.com/a.jpg'],
      }).discover_eligible,
      false,
    );
    assert.strictEqual(
      buildPublicProfileProjection({ discover_eligible: 'true' })
        .discover_eligible,
      false,
    );
    assert.strictEqual(
      buildPublicProfileProjection({
        discover_eligible: true,
        profile_completed: false,
        active: false,
      }).discover_eligible,
      true,
    );
  });

  it('create writes a full public snapshot', async () => {
    const db = new MemoryFirestore();
    const result = await handlePublicProfileUserWritten(
      writtenEvent({ before: undefined, after: privateUser() }),
      { db },
    );

    assert.strictEqual(result.skipped, null);
    assert.strictEqual(result.written, true);
    const snap = await publicDoc(db).get();
    assert.ok(snap.exists);
    assert.strictEqual(snap.data().company, 'Acme');
    assert.ok(!('email' in snap.data()));
    assert.deepStrictEqual(userStoreKeys(db), []);
  });

  it('removed optional public field disappears from the public document', async () => {
    const db = new MemoryFirestore();
    await handlePublicProfileUserWritten(
      writtenEvent({ before: undefined, after: privateUser() }),
      { db },
    );

    const withoutCompany = privateUser({ company: '' });
    delete withoutCompany.company;
    const result = await handlePublicProfileUserWritten(
      writtenEvent({
        before: privateUser(),
        after: withoutCompany,
      }),
      { db },
    );

    assert.strictEqual(result.skipped, null);
    const data = (await publicDoc(db).get()).data();
    assert.ok(!('company' in data));
    assert.strictEqual(data.name, 'Ada');
  });

  it('private-field-only updates do not rewrite an identical public snapshot', async () => {
    const db = new MemoryFirestore();
    await handlePublicProfileUserWritten(
      writtenEvent({ before: undefined, after: privateUser() }),
      { db },
    );
    const before = (await publicDoc(db).get()).data();

    const result = await handlePublicProfileUserWritten(
      writtenEvent({
        before: privateUser(),
        after: privateUser({
          last_active_at: '2026-08-28T12:00:00.000Z',
          email: 'other@example.com',
          frequency_vector: { depth: 0.1 },
        }),
      }),
      { db },
    );

    assert.strictEqual(result.skipped, 'unchanged');
    assert.deepStrictEqual((await publicDoc(db).get()).data(), before);
  });

  it('discover_eligible false keeps the public document and marks it false', async () => {
    const db = new MemoryFirestore();
    await handlePublicProfileUserWritten(
      writtenEvent({
        before: undefined,
        after: privateUser({ discover_eligible: true }),
      }),
      { db },
    );

    const result = await handlePublicProfileUserWritten(
      writtenEvent({
        before: privateUser({ discover_eligible: true }),
        after: privateUser({ discover_eligible: false }),
      }),
      { db },
    );

    assert.strictEqual(result.skipped, null);
    const snap = await publicDoc(db).get();
    assert.ok(snap.exists);
    assert.strictEqual(snap.data().discover_eligible, false);
    assert.strictEqual(snap.data().name, 'Ada');
    assert.strictEqual(snap.data().profile_photo_url, 'https://example.com/a.jpg');
  });

  it('user delete leaves a safe non-discoverable snapshot and does not delete it', async () => {
    const db = new MemoryFirestore();
    await handlePublicProfileUserWritten(
      writtenEvent({
        before: undefined,
        after: privateUser({ discover_eligible: true }),
      }),
      { db },
    );

    const result = await handlePublicProfileUserWritten(
      writtenEvent({
        before: privateUser({
          discover_eligible: true,
          email: 'secret@example.com',
          frequency_vector: { depth: 1 },
        }),
        after: undefined,
        afterExists: false,
        beforeExists: true,
      }),
      { db },
    );

    assert.strictEqual(result.skipped, null);
    const snap = await publicDoc(db).get();
    assert.ok(snap.exists);
    assert.strictEqual(snap.data().discover_eligible, false);
    assert.strictEqual(snap.data().name, 'Ada');
    assert.ok(!('email' in snap.data()));
    assert.ok(!('frequency_vector' in snap.data()));
    assert.deepStrictEqual(userStoreKeys(db), []);
  });

  it('firestore.indexes.json keeps users Passport composite and adds public_profiles', () => {
    const indexes = JSON.parse(
      fs.readFileSync(
        path.join(__dirname, '../../firestore.indexes.json'),
        'utf8',
      ),
    );
    const composites = indexes.indexes.filter(
      (entry) =>
        Array.isArray(entry.fields) &&
        entry.fields.some((field) => field.fieldPath === 'discover_eligible') &&
        entry.fields.some((field) => field.fieldPath === 'home_country') &&
        entry.fields.some((field) => field.fieldPath === 'home_city'),
    );
    const groups = composites.map((entry) => entry.collectionGroup).sort();
    assert.deepStrictEqual(groups, ['public_profiles', 'users']);
  });
});
