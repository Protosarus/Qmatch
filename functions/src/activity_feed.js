'use strict';

const crypto = require('crypto');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

const REGION = 'europe-west1';
const PROFILE_DOCUMENT_PATH = 'users/{uid}';
const MATCH_DOCUMENT_PATH = 'matches/{matchId}';
const SUPER_RESONANCE_DOCUMENT_PATH =
  'super_resonance_signals/{signalId}';

const ACTIVITY_TYPES = Object.freeze({
  PHOTO_ADDED: 'photo_added',
  BIO_UPDATED: 'bio_updated',
  WORK_EDUCATION_UPDATED: 'work_education_updated',
  MATCH_CREATED: 'match_created',
  SUPER_RESONANCE_RECEIVED: 'super_resonance_received',
  ANTHEM_UPDATED: 'anthem_updated',
});

function nonEmptyString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function normalizedPhotos(value) {
  if (!Array.isArray(value)) return [];
  return [
    ...new Set(
      value
        .map(nonEmptyString)
        .filter(Boolean),
    ),
  ];
}

function actorSnapshot(data) {
  return {
    actor_name: nonEmptyString(data && data.name),
    actor_photo_url: nonEmptyString(
      data && data.profile_photo_url,
    ),
  };
}

function eventTime(event, preferred) {
  if (preferred && typeof preferred.toDate === 'function') {
    return preferred;
  }

  const raw = event && event.time;
  if (typeof raw === 'string') {
    const parsed = new Date(raw);
    if (!Number.isNaN(parsed.getTime())) {
      return Timestamp.fromDate(parsed);
    }
  }

  return Timestamp.now();
}

function eventDocId({
  event,
  recipientUid,
  type,
  fallbackSourceId,
}) {
  const eventId = nonEmptyString(event && event.id) ||
    nonEmptyString(fallbackSourceId);

  return crypto
    .createHash('sha256')
    .update(`${eventId}|${recipientUid}|${type}`, 'utf8')
    .digest('hex');
}

function activityRef(db, recipientUid, eventId) {
  return db.doc(
    `users/${recipientUid}/activity_feed/${eventId}`,
  );
}

async function activeMatchedPeers(db, actorUid) {
  const snap = await db
    .collection('matches')
    .where('users', 'array-contains', actorUid)
    .get();

  const peers = new Set();

  for (const doc of snap.docs) {
    const data = doc.data() || {};
    if (data.state !== 'active') continue;

    const users = Array.isArray(data.users)
      ? data.users.map(nonEmptyString).filter(Boolean)
      : [];

    if (users.length !== 2 || !users.includes(actorUid)) {
      continue;
    }

    const other = users.find((uid) => uid !== actorUid);
    if (other) peers.add(other);
  }

  return [...peers];
}

async function writeProfileActivity({
  db,
  event,
  actorUid,
  actorData,
  recipients,
  change,
}) {
  if (recipients.length === 0) return 0;

  const batch = db.batch();
  const createdAt = eventTime(event);

  for (const recipientUid of recipients) {
    const id = eventDocId({
      event,
      recipientUid,
      type: change.type,
      fallbackSourceId: `profile:${actorUid}`,
    });

    batch.set(activityRef(db, recipientUid, id), {
      schema_version: 1,
      type: change.type,
      actor_uid: actorUid,
      ...actorSnapshot(actorData),
      created_at: createdAt,
      source_collection: 'users',
      source_id: actorUid,
      ...(change.extra || {}),
    });
  }

  await batch.commit();
  return recipients.length;
}

async function handleProfileActivityWritten(event, deps = {}) {
  const db = deps.db || getFirestore();
  const before = event.data && event.data.before
    ? event.data.before.data()
    : null;
  const after = event.data && event.data.after
    ? event.data.after.data()
    : null;

  if (!before || !after) {
    return { skipped: 'create_or_delete' };
  }

  if (
    before.profile_completed !== true ||
    after.profile_completed !== true
  ) {
    return { skipped: 'profile_not_previously_complete' };
  }

  const actorUid = nonEmptyString(
    event.params && event.params.uid,
  );
  if (!actorUid) {
    return { skipped: 'missing_actor_uid' };
  }

  const changes = [];

  const beforePhotos = normalizedPhotos(before.photos);
  const afterPhotos = normalizedPhotos(after.photos);
  const beforePhotoSet = new Set(beforePhotos);
  const addedPhotos = afterPhotos.filter(
    (url) => !beforePhotoSet.has(url),
  );

  if (addedPhotos.length > 0) {
    changes.push({
      type: ACTIVITY_TYPES.PHOTO_ADDED,
      extra: {
        photo_url: addedPhotos[0],
        photo_added_count: addedPhotos.length,
      },
    });
  }

  if (
    nonEmptyString(before.bio) !==
    nonEmptyString(after.bio)
  ) {
    changes.push({
      type: ACTIVITY_TYPES.BIO_UPDATED,
    });
  }

  const changedWorkEducation = [];

  if (
    nonEmptyString(before.education) !==
    nonEmptyString(after.education)
  ) {
    changedWorkEducation.push('education');
  }

  if (
    nonEmptyString(before.occupation) !==
    nonEmptyString(after.occupation)
  ) {
    changedWorkEducation.push('occupation');
  }

  if (changedWorkEducation.length > 0) {
    changes.push({
      type: ACTIVITY_TYPES.WORK_EDUCATION_UPDATED,
      extra: {
        changed_fields: changedWorkEducation,
      },
    });
  }

  if (changes.length === 0) {
    return { skipped: 'no_feed_relevant_change' };
  }

  const recipients = await activeMatchedPeers(db, actorUid);
  if (recipients.length === 0) {
    return { skipped: 'no_active_matches' };
  }

  let writes = 0;

  for (const change of changes) {
    writes += await writeProfileActivity({
      db,
      event,
      actorUid,
      actorData: after,
      recipients,
      change,
    });
  }

  return {
    skipped: null,
    event_types: changes.map((change) => change.type),
    recipients: recipients.length,
    writes,
  };
}

async function handleMatchActivityCreated(event, deps = {}) {
  const db = deps.db || getFirestore();
  const match = event.data ? event.data.data() : null;

  if (!match || match.state !== 'active') {
    return { skipped: 'inactive_or_missing_match' };
  }

  const users = Array.isArray(match.users)
    ? [...new Set(match.users.map(nonEmptyString).filter(Boolean))]
    : [];

  if (users.length !== 2) {
    return { skipped: 'invalid_participants' };
  }

  const matchId =
    nonEmptyString(event.params && event.params.matchId) ||
    nonEmptyString(match.match_id);

  if (!matchId) {
    return { skipped: 'missing_match_id' };
  }

  const userSnaps = await Promise.all(
    users.map((uid) => db.doc(`users/${uid}`).get()),
  );

  const userData = new Map();
  for (let i = 0; i < users.length; i += 1) {
    userData.set(
      users[i],
      userSnaps[i].exists ? userSnaps[i].data() || {} : {},
    );
  }

  const batch = db.batch();
  const createdAt = eventTime(event, match.created_at);

  for (const recipientUid of users) {
    const actorUid = users.find(
      (uid) => uid !== recipientUid,
    );

    const id = eventDocId({
      event,
      recipientUid,
      type: ACTIVITY_TYPES.MATCH_CREATED,
      fallbackSourceId: `match:${matchId}`,
    });

    batch.set(activityRef(db, recipientUid, id), {
      schema_version: 1,
      type: ACTIVITY_TYPES.MATCH_CREATED,
      actor_uid: actorUid,
      ...actorSnapshot(userData.get(actorUid)),
      created_at: createdAt,
      source_collection: 'matches',
      source_id: matchId,
      match_id: matchId,
      thread_id: nonEmptyString(match.thread_id),
    });
  }

  await batch.commit();

  return {
    skipped: null,
    writes: 2,
  };
}

async function handleSuperResonanceActivityCreated(
  event,
  deps = {},
) {
  const db = deps.db || getFirestore();
  const signal = event.data ? event.data.data() : null;

  if (!signal) {
    return { skipped: 'missing_signal' };
  }

  const actorUid = nonEmptyString(signal.from_uid);
  const recipientUid = nonEmptyString(signal.to_uid);

  if (
    !actorUid ||
    !recipientUid ||
    actorUid === recipientUid
  ) {
    return { skipped: 'invalid_signal_users' };
  }

  const signalId =
    nonEmptyString(event.params && event.params.signalId) ||
    nonEmptyString(signal.signal_id);

  if (!signalId) {
    return { skipped: 'missing_signal_id' };
  }

  const actorDoc = await db.doc(`users/${actorUid}`).get();
  const actorData = actorDoc.exists
    ? actorDoc.data() || {}
    : {};

  const id = eventDocId({
    event,
    recipientUid,
    type: ACTIVITY_TYPES.SUPER_RESONANCE_RECEIVED,
    fallbackSourceId: `super_resonance:${signalId}`,
  });

  await activityRef(db, recipientUid, id).set({
    schema_version: 1,
    type: ACTIVITY_TYPES.SUPER_RESONANCE_RECEIVED,
    actor_uid: actorUid,
    ...actorSnapshot(actorData),
    created_at: eventTime(event, signal.created_at),
    source_collection: 'super_resonance_signals',
    source_id: signalId,
    signal_id: signalId,
  });

  return {
    skipped: null,
    writes: 1,
  };
}

module.exports = {
  REGION,
  PROFILE_DOCUMENT_PATH,
  MATCH_DOCUMENT_PATH,
  SUPER_RESONANCE_DOCUMENT_PATH,
  ACTIVITY_TYPES,
  normalizedPhotos,
  activeMatchedPeers,
  handleProfileActivityWritten,
  handleMatchActivityCreated,
  handleSuperResonanceActivityCreated,
};
