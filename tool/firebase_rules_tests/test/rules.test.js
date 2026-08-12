/**
 * P2C-1A Firebase rules tests.
 *
 * Run from this directory (requires Firebase CLI + Java for emulators):
 *   npm install
 *   npm test
 *
 * Or from repo root:
 *   (cd tool/firebase_rules_tests && npm install && npm test)
 */
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  collection,
  addDoc,
} = require('firebase/firestore');
const {
  ref,
  uploadBytes,
  deleteObject,
  getBytes,
} = require('firebase/storage');

const PROJECT_ID = 'demo-qmatch';
const FIRESTORE_RULES = readFileSync(
  resolve(__dirname, '../../../firestore.rules'),
  'utf8',
);
const STORAGE_RULES = readFileSync(
  resolve(__dirname, '../../../storage.rules'),
  'utf8',
);

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: FIRESTORE_RULES },
    storage: { rules: STORAGE_RULES },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.clearStorage();
});

function authedFirestore(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function unauthFirestore() {
  return testEnv.unauthenticatedContext().firestore();
}

function authedStorage(uid) {
  return testEnv.authenticatedContext(uid).storage();
}

function unauthStorage() {
  return testEnv.unauthenticatedContext().storage();
}

async function seedMutualLikes(a, b) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, `users/${a}/swipes/${b}`), { direction: 'like' });
    await setDoc(doc(db, `users/${b}/swipes/${a}`), { direction: 'like' });
  });
}

describe('Firestore rules', () => {
  it('1. unauthenticated unknown read denied', async () => {
    await assertFails(getDoc(doc(unauthFirestore(), 'unknown_collection/x')));
  });

  it('2. unauthenticated unknown write denied', async () => {
    await assertFails(
      setDoc(doc(unauthFirestore(), 'unknown_collection/x'), { a: 1 }),
    );
  });

  it('3. authenticated user may read permitted own data', async () => {
    const uid = 'userA';
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `users/${uid}`), {
        uid,
        discover_eligible: false,
        display_name: 'A',
      });
    });
    await assertSucceeds(getDoc(doc(authedFirestore(uid), `users/${uid}`)));
  });

  it('4. user cannot write another user’s private profile', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userB'), {
        uid: 'userB',
        discover_eligible: false,
        display_name: 'B',
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userB'), {
        display_name: 'Hacked',
      }),
    );
  });

  it('5. user cannot read another user’s private assessment answers', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userB/assessments/iq'), {
        answers: { q1: 'secret' },
        confidence: 0.9,
      });
    });
    await assertFails(
      getDoc(doc(authedFirestore('userA'), 'users/userB/assessments/iq')),
    );
  });

  it('6. user cannot edit protected derived compatibility / eligibility fields', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        iq_score: 10,
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        discover_eligible: true,
      }),
    );
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        iq_score: 99,
      }),
    );
  });

  it('7. user cannot create arbitrary matches', async () => {
    await assertFails(
      setDoc(doc(authedFirestore('userA'), 'matches/userA_userB'), {
        match_id: 'userA_userB',
        user_a: 'userA',
        user_b: 'userB',
        users: ['userA', 'userB'],
        state: 'active',
      }),
    );
  });

  it('8. non-member cannot read conversation', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'threads/userA_userB'), {
        thread_id: 'userA_userB',
        participants: ['userA', 'userB'],
        status: 'active',
      });
    });
    await assertFails(
      getDoc(doc(authedFirestore('userC'), 'threads/userA_userB')),
    );
  });

  it('9. conversation member can read permitted conversation data', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'threads/userA_userB'), {
        thread_id: 'userA_userB',
        participants: ['userA', 'userB'],
        status: 'active',
      });
    });
    await assertSucceeds(
      getDoc(doc(authedFirestore('userA'), 'threads/userA_userB')),
    );
  });

  it('10. non-member cannot send message', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'matches/userA_userB'), {
        users: ['userA', 'userB'],
        state: 'active',
        thread_id: 'userA_userB',
      });
      await setDoc(doc(db, 'threads/userA_userB'), {
        participants: ['userA', 'userB'],
        status: 'active',
        match_id: 'userA_userB',
      });
    });
    await assertFails(
      setDoc(doc(authedFirestore('userC'), 'threads/userA_userB/messages/m1'), {
        sender_id: 'userC',
        type: 'text',
        text: 'nope',
      }),
    );
  });

  it('11. member can send valid message', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'matches/userA_userB'), {
        users: ['userA', 'userB'],
        state: 'active',
        thread_id: 'userA_userB',
      });
      await setDoc(doc(db, 'threads/userA_userB'), {
        participants: ['userA', 'userB'],
        status: 'active',
        match_id: 'userA_userB',
      });
    });
    await assertSucceeds(
      setDoc(doc(authedFirestore('userA'), 'threads/userA_userB/messages/m1'), {
        sender_id: 'userA',
        type: 'text',
        text: 'hello',
      }),
    );
  });

  it('12. blocked relationship follows documented policy (owner-only blocks)', async () => {
    await assertSucceeds(
      setDoc(doc(authedFirestore('userA'), 'users/userA/blocks/userB'), {
        blocked_uid: 'userB',
      }),
    );
    await assertFails(
      getDoc(doc(authedFirestore('userB'), 'users/userA/blocks/userB')),
    );
  });

  it('13. report owner can create a valid report', async () => {
    await assertSucceeds(
      addDoc(collection(authedFirestore('userA'), 'reports'), {
        reporter_uid: 'userA',
        reported_uid: 'userB',
        reason: 'spam',
        status: 'new',
      }),
    );
  });

  it('14. report cannot be read by an unrelated user', async () => {
    let reportId;
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const refDoc = doc(collection(ctx.firestore(), 'reports'));
      reportId = refDoc.id;
      await setDoc(refDoc, {
        reporter_uid: 'userA',
        reported_uid: 'userB',
        reason: 'spam',
        status: 'new',
      });
    });
    await assertFails(getDoc(doc(authedFirestore('userC'), `reports/${reportId}`)));
    await assertFails(getDoc(doc(authedFirestore('userA'), `reports/${reportId}`)));
  });

  it('15. deletion request is owner-controlled', async () => {
    await assertSucceeds(
      setDoc(doc(authedFirestore('userA'), 'account_deletion_requests/userA'), {
        uid: 'userA',
        status: 'requested',
      }),
    );
    await assertFails(
      setDoc(doc(authedFirestore('userA'), 'account_deletion_requests/userB'), {
        uid: 'userB',
        status: 'requested',
      }),
    );
  });

  it('16. unknown collection denied', async () => {
    await assertFails(
      setDoc(doc(authedFirestore('userA'), 'totally_unknown/doc1'), { x: 1 }),
    );
    await assertFails(
      getDoc(doc(authedFirestore('userA'), 'totally_unknown/doc1')),
    );
  });

  it('mutual like allows match create; still rejects forged third party', async () => {
    await seedMutualLikes('userA', 'userB');
    await assertSucceeds(
      setDoc(doc(authedFirestore('userA'), 'matches/userA_userB'), {
        match_id: 'userA_userB',
        user_a: 'userA',
        user_b: 'userB',
        users: ['userA', 'userB'],
        state: 'active',
        thread_id: 'userA_userB',
        compat: {},
      }),
    );
    await assertFails(
      setDoc(doc(authedFirestore('userC'), 'matches/userA_userC'), {
        match_id: 'userA_userC',
        user_a: 'userA',
        user_b: 'userC',
        users: ['userA', 'userC'],
        state: 'active',
        thread_id: 'userA_userC',
      }),
    );
  });

  it('P2C-1C-4A owner can update canonical display name (name)', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        name: '',
      });
    });
    await assertSucceeds(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        name: 'Ada',
      }),
    );
  });

  it('P2C-1C-4A other user cannot update another display name', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        name: 'Ada',
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userB'), 'users/userA'), {
        name: 'Hacker',
      }),
    );
  });

  it('P2C-1C-4A name update cannot mutate protected discover_eligible', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        name: 'Ada',
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        name: 'Ada Yeni',
        discover_eligible: true,
      }),
    );
  });
});

describe('Storage rules', () => {
  const smallJpeg = Uint8Array.from([
    0xff, 0xd8, 0xff, 0xd9, // minimal JPEG markers
  ]);

  it('17. unknown Storage path denied', async () => {
    const r = ref(authedStorage('userA'), 'other_path/userA/file.bin');
    await assertFails(
      uploadBytes(r, smallJpeg, { contentType: 'image/jpeg' }),
    );
  });

  it('18. user can upload valid own profile image', async () => {
    const r = ref(
      authedStorage('userA'),
      'profile_photos/userA/profile_userA_1.jpg',
    );
    await assertSucceeds(
      uploadBytes(r, smallJpeg, { contentType: 'image/jpeg' }),
    );
  });

  it('19. user cannot upload to another user’s path', async () => {
    const r = ref(
      authedStorage('userA'),
      'profile_photos/userB/stolen.jpg',
    );
    await assertFails(
      uploadBytes(r, smallJpeg, { contentType: 'image/jpeg' }),
    );
  });

  it('20. invalid content type denied', async () => {
    const r = ref(
      authedStorage('userA'),
      'profile_photos/userA/not_image.bin',
    );
    await assertFails(
      uploadBytes(r, smallJpeg, { contentType: 'application/octet-stream' }),
    );
  });

  it('21. oversized image denied', async () => {
    const big = new Uint8Array(5 * 1024 * 1024 + 1);
    const r = ref(
      authedStorage('userA'),
      'profile_photos/userA/too_big.jpg',
    );
    await assertFails(uploadBytes(r, big, { contentType: 'image/jpeg' }));
  });

  it('22. unauthorized delete denied', async () => {
    const path = 'profile_photos/userA/profile_userA_1.jpg';
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await uploadBytes(ref(ctx.storage(), path), smallJpeg, {
        contentType: 'image/jpeg',
      });
    });
    await assertFails(deleteObject(ref(authedStorage('userB'), path)));
    await assertSucceeds(deleteObject(ref(authedStorage('userA'), path)));
  });

  it('unauthenticated storage read of profile path denied', async () => {
    const path = 'profile_photos/userA/profile_userA_1.jpg';
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await uploadBytes(ref(ctx.storage(), path), smallJpeg, {
        contentType: 'image/jpeg',
      });
    });
    await assertFails(getBytes(ref(unauthStorage(), path)));
  });
});

describe('HOTFIX canonical_v1 profile rules', () => {
  const profilePath = (uid) => `users/${uid}/profiles/canonical_v1`;
  const sampleProfile = {
    schema_version: 'qmatch_canonical_profile_v1',
    owner_uid: 'userA',
    measured_dimension_count: 4,
    profile_status: 'partial',
  };

  it('owner can create own canonical_v1', async () => {
    await assertSucceeds(
      setDoc(doc(authedFirestore('userA'), profilePath('userA')), {
        ...sampleProfile,
        owner_uid: 'userA',
      }),
    );
  });

  it('owner can read own canonical_v1', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), profilePath('userA')), {
        ...sampleProfile,
        owner_uid: 'userA',
      });
    });
    await assertSucceeds(
      getDoc(doc(authedFirestore('userA'), profilePath('userA'))),
    );
  });

  it('owner can update own canonical_v1', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), profilePath('userA')), {
        ...sampleProfile,
        owner_uid: 'userA',
      });
    });
    await assertSucceeds(
      updateDoc(doc(authedFirestore('userA'), profilePath('userA')), {
        measured_dimension_count: 14,
      }),
    );
  });

  it('cross-UID read of canonical_v1 denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), profilePath('userB')), {
        ...sampleProfile,
        owner_uid: 'userB',
      });
    });
    await assertFails(
      getDoc(doc(authedFirestore('userA'), profilePath('userB'))),
    );
  });

  it('cross-UID create/update of canonical_v1 denied', async () => {
    await assertFails(
      setDoc(doc(authedFirestore('userA'), profilePath('userB')), {
        ...sampleProfile,
        owner_uid: 'userB',
      }),
    );
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), profilePath('userB')), {
        ...sampleProfile,
        owner_uid: 'userB',
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), profilePath('userB')), {
        measured_dimension_count: 20,
      }),
    );
  });

  it('unauthenticated read/write of canonical_v1 denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), profilePath('userA')), {
        ...sampleProfile,
        owner_uid: 'userA',
      });
    });
    await assertFails(
      getDoc(doc(unauthFirestore(), profilePath('userA'))),
    );
    await assertFails(
      setDoc(doc(unauthFirestore(), profilePath('userA')), sampleProfile),
    );
  });

  it('owner delete of canonical_v1 denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), profilePath('userA')), {
        ...sampleProfile,
        owner_uid: 'userA',
      });
    });
    const { deleteDoc } = require('firebase/firestore');
    await assertFails(
      deleteDoc(doc(authedFirestore('userA'), profilePath('userA'))),
    );
  });
});

describe('Match/thread lifecycle harden v1', () => {
  const pair = 'userA_userB';

  async function seedActiveMatchAndThread() {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, `matches/${pair}`), {
        match_id: pair,
        user_a: 'userA',
        user_b: 'userB',
        users: ['userA', 'userB'],
        state: 'active',
        thread_id: pair,
      });
      await setDoc(doc(db, `threads/${pair}`), {
        thread_id: pair,
        match_id: pair,
        participants: ['userA', 'userB'],
        status: 'active',
      });
    });
  }

  it('active match member can read match', async () => {
    await seedActiveMatchAndThread();
    await assertSucceeds(getDoc(doc(authedFirestore('userA'), `matches/${pair}`)));
  });

  it('unmatched match read rejected', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `matches/${pair}`), {
        users: ['userA', 'userB'],
        state: 'unmatched',
        thread_id: pair,
      });
    });
    await assertFails(getDoc(doc(authedFirestore('userA'), `matches/${pair}`)));
  });

  it('blocked match read rejected', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `matches/${pair}`), {
        users: ['userA', 'userB'],
        state: 'blocked',
        thread_id: pair,
      });
    });
    await assertFails(getDoc(doc(authedFirestore('userA'), `matches/${pair}`)));
  });

  it('thread creation without valid active match rejected', async () => {
    await seedMutualLikes('userA', 'userB');
    await assertFails(
      setDoc(doc(authedFirestore('userA'), `threads/${pair}`), {
        thread_id: pair,
        match_id: pair,
        participants: ['userA', 'userB'],
        status: 'active',
      }),
    );
  });

  it('thread creation succeeds when active match exists', async () => {
    await seedMutualLikes('userA', 'userB');
    await assertSucceeds(
      setDoc(doc(authedFirestore('userA'), `matches/${pair}`), {
        match_id: pair,
        user_a: 'userA',
        user_b: 'userB',
        users: ['userA', 'userB'],
        state: 'active',
        thread_id: pair,
        compat: {},
      }),
    );
    await assertSucceeds(
      setDoc(doc(authedFirestore('userA'), `threads/${pair}`), {
        thread_id: pair,
        match_id: pair,
        participants: ['userA', 'userB'],
        status: 'active',
      }),
    );
  });

  it('viewer block prevents match create', async () => {
    await seedMutualLikes('userA', 'userB');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA/blocks/userB'), {
        blocked_uid: 'userB',
      });
    });
    await assertFails(
      setDoc(doc(authedFirestore('userA'), `matches/${pair}`), {
        match_id: pair,
        user_a: 'userA',
        user_b: 'userB',
        users: ['userA', 'userB'],
        state: 'active',
        thread_id: pair,
      }),
    );
  });

  it('candidate block prevents match create', async () => {
    await seedMutualLikes('userA', 'userB');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userB/blocks/userA'), {
        blocked_uid: 'userA',
      });
    });
    await assertFails(
      setDoc(doc(authedFirestore('userA'), `matches/${pair}`), {
        match_id: pair,
        user_a: 'userA',
        user_b: 'userB',
        users: ['userA', 'userB'],
        state: 'active',
        thread_id: pair,
      }),
    );
  });

  it('either-direction block prevents thread create even if match seeded', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, `matches/${pair}`), {
        users: ['userA', 'userB'],
        state: 'active',
        thread_id: pair,
      });
      await setDoc(doc(db, 'users/userB/blocks/userA'), {
        blocked_uid: 'userA',
      });
    });
    await assertFails(
      setDoc(doc(authedFirestore('userA'), `threads/${pair}`), {
        thread_id: pair,
        match_id: pair,
        participants: ['userA', 'userB'],
        status: 'active',
      }),
    );
  });

  it('fake system sender on arbitrary message id rejected', async () => {
    await seedActiveMatchAndThread();
    await assertFails(
      setDoc(doc(authedFirestore('userA'), `threads/${pair}/messages/fake1`), {
        sender_id: 'system',
        type: 'system',
        text: 'You matched!',
      }),
    );
  });

  it('valid normal user text message allowed', async () => {
    await seedActiveMatchAndThread();
    await assertSucceeds(
      setDoc(doc(authedFirestore('userA'), `threads/${pair}/messages/m_ok`), {
        sender_id: 'userA',
        type: 'text',
        text: 'hi there',
      }),
    );
  });

  it('fixed system_match_v1 bootstrap allowed; rematch reactivation denied', async () => {
    await seedActiveMatchAndThread();
    await assertSucceeds(
      setDoc(
        doc(authedFirestore('userA'), `threads/${pair}/messages/system_match_v1`),
        {
          sender_id: 'system',
          type: 'system',
          text: 'You matched!',
        },
      ),
    );
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `matches/${pair}`), {
        users: ['userA', 'userB'],
        state: 'unmatched',
        thread_id: pair,
        user_a: 'userA',
        user_b: 'userB',
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), `matches/${pair}`), {
        state: 'active',
      }),
    );
  });

  it('unmatched may upgrade to blocked; already-closed thread status stays closed', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, `matches/${pair}`), {
        users: ['userA', 'userB'],
        state: 'unmatched',
        thread_id: pair,
        user_a: 'userA',
        user_b: 'userB',
      });
      await setDoc(doc(db, `threads/${pair}`), {
        participants: ['userA', 'userB'],
        status: 'closed',
        match_id: pair,
      });
    });
    await assertSucceeds(
      updateDoc(doc(authedFirestore('userA'), `matches/${pair}`), {
        state: 'blocked',
      }),
    );
    await assertSucceeds(
      updateDoc(doc(authedFirestore('userA'), `threads/${pair}`), {
        status: 'closed',
        closed_reason: 'blocked',
      }),
    );
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), `threads/${pair}`), {
        status: 'active',
      }),
    );
  });
});
