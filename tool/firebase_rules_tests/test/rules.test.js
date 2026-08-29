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
  deleteDoc,
  collection,
  addDoc,
  getDocs,
  collectionGroup,
  query,
  where,
  deleteField,
  serverTimestamp,
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
    await assertFails(
      getDoc(doc(authedFirestore('userA'), 'users/userB/blocks/userA')),
    );
  });

  it('client Like write is denied for eligible users', async () => {
    await assertFails(
      setDoc(doc(authedFirestore('userA'), 'users/userA/swipes/userB'), {
        from_uid: 'userA',
        target_uid: 'userB',
        direction: 'like',
        source: 'discover',
      }),
    );
    await assertFails(
      setDoc(doc(authedFirestore('userB'), 'users/userB/swipes/userA'), {
        from_uid: 'userB',
        target_uid: 'userA',
        direction: 'like',
        source: 'discover',
      }),
    );
  });

  it('blocked viewer cannot write Like toward the blocker', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userB/blocks/userA'), {
        blocked_uid: 'userA',
        reason: 'secret',
      });
    });
    await assertFails(
      setDoc(doc(authedFirestore('userA'), 'users/userA/swipes/userB'), {
        from_uid: 'userA',
        target_uid: 'userB',
        direction: 'like',
        source: 'discover',
      }),
    );
  });

  it('blocked viewer may still write Pass', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userB/blocks/userA'), {
        blocked_uid: 'userA',
      });
    });
    await assertSucceeds(
      setDoc(doc(authedFirestore('userA'), 'users/userA/swipes/userB'), {
        from_uid: 'userA',
        target_uid: 'userB',
        direction: 'pass',
        source: 'discover',
      }),
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

  it('stale_user_v1 owner may revoke discover_eligible to false', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: true,
        name: 'Ada',
      });
    });
    await assertSucceeds(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        discover_eligible: false,
        account_deletion_requested: true,
      }),
    );
  });
});

describe('C1 active and account-deletion protected writes', () => {
  it('A create own users doc with active=true is allowed', async () => {
    await assertSucceeds(
      setDoc(doc(authedFirestore('userA'), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
      }),
    );
  });

  it('B create own users doc with active=false is denied', async () => {
    await assertFails(
      setDoc(doc(authedFirestore('userA'), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: false,
      }),
    );
  });

  it('C client cannot update active true to false', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        active: false,
      }),
    );
  });

  it('D client cannot update active false to true', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: false,
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        active: true,
      }),
    );
  });

  it('E unchanged active with unrelated allowed field update is allowed', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        name: 'Ada',
      });
    });
    await assertSucceeds(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        name: 'Ada Yeni',
        active: true,
      }),
    );
  });

  it('F create with account_deletion_requested omitted or false is allowed', async () => {
    await assertSucceeds(
      setDoc(doc(authedFirestore('userA'), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
      }),
    );
    await assertSucceeds(
      setDoc(doc(authedFirestore('userB'), 'users/userB'), {
        uid: 'userB',
        discover_eligible: false,
        active: true,
        account_deletion_requested: false,
      }),
    );
  });

  it('G create with account_deletion_requested=true is denied', async () => {
    await assertFails(
      setDoc(doc(authedFirestore('userA'), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        account_deletion_requested: true,
      }),
    );
  });

  it('H update missing account_deletion_requested to true is allowed', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: true,
        active: true,
      });
    });
    await assertSucceeds(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        account_deletion_requested: true,
        discover_eligible: false,
      }),
    );
  });

  it('H update false account_deletion_requested to true is allowed', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: true,
        active: true,
        account_deletion_requested: false,
      });
    });
    await assertSucceeds(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        account_deletion_requested: true,
        discover_eligible: false,
      }),
    );
  });

  it('I true account_deletion_requested may stay true with another allowed field', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        account_deletion_requested: true,
        name: 'Ada',
      });
    });
    await assertSucceeds(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        name: 'Ada Yeni',
        account_deletion_requested: true,
      }),
    );
  });

  it('J client cannot update account_deletion_requested true to false', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        account_deletion_requested: true,
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        account_deletion_requested: false,
      }),
    );
  });

  it('K client cannot delete account_deletion_requested after true', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        account_deletion_requested: true,
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        account_deletion_requested: deleteField(),
      }),
    );
  });

  it('L non-boolean account_deletion_requested is denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        account_deletion_requested: 'true',
      }),
    );
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        account_deletion_requested: 1,
      }),
    );
  });
});

describe('C2-T1 assessment_verification_v1 protected writes', () => {
  const trustedMap = {
    schema_version: 'assessment_verification_v1',
    flow: 'iq',
    grant_reason: 'server_test',
  };

  it('A create own users doc with assessment_verification_v1 omitted is allowed', async () => {
    await assertSucceeds(
      setDoc(doc(authedFirestore('userA'), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
      }),
    );
  });

  it('B create with assessment_verification_v1 empty map is denied', async () => {
    await assertFails(
      setDoc(doc(authedFirestore('userA'), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        assessment_verification_v1: {},
      }),
    );
  });

  it('C create with assessment_verification_v1.flow complete is denied', async () => {
    await assertFails(
      setDoc(doc(authedFirestore('userA'), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        assessment_verification_v1: { flow: 'complete' },
      }),
    );
  });

  it('D create with assessment_verification_v1 null is denied', async () => {
    await assertFails(
      setDoc(doc(authedFirestore('userA'), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        assessment_verification_v1: null,
      }),
    );
  });

  it('existing map: bio-only update is allowed', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        bio: 'hello',
        assessment_verification_v1: trustedMap,
      });
    });
    await assertSucceeds(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        bio: 'updated bio',
      }),
    );
  });

  it('existing map: profile_completed mirror rewrite is allowed', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        profile_completed: false,
        assessment_verification_v1: trustedMap,
      });
    });
    await assertSucceeds(
      setDoc(
        doc(authedFirestore('userA'), 'users/userA'),
        { profile_completed: true },
        { merge: true },
      ),
    );
  });

  it('existing map: assessment completion mirrors remain writable', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        test_completed: false,
        assessment_flow_completed: false,
        assessment_verification_v1: trustedMap,
      });
    });
    await assertSucceeds(
      setDoc(
        doc(authedFirestore('userA'), 'users/userA'),
        {
          test_completed: true,
          assessment_flow_completed: true,
        },
        { merge: true },
      ),
    );
  });

  it('existing map: last_active_at merge is allowed', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        assessment_verification_v1: trustedMap,
      });
    });
    await assertSucceeds(
      setDoc(
        doc(authedFirestore('userA'), 'users/userA'),
        {
          last_active_at: serverTimestamp(),
          updated_at: serverTimestamp(),
        },
        { merge: true },
      ),
    );
  });

  it('existing map: account_deletion_requested false to true is allowed', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: true,
        active: true,
        assessment_verification_v1: trustedMap,
      });
    });
    await assertSucceeds(
      setDoc(
        doc(authedFirestore('userA'), 'users/userA'),
        {
          account_deletion_requested: true,
          discover_eligible: false,
        },
        { merge: true },
      ),
    );
  });

  it('existing map: whole-map replacement is denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        assessment_verification_v1: trustedMap,
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        assessment_verification_v1: {
          schema_version: 'assessment_verification_v1',
          flow: 'complete',
          grant_reason: 'forged',
        },
      }),
    );
  });

  it('existing map: set to null is denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        assessment_verification_v1: trustedMap,
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        assessment_verification_v1: null,
      }),
    );
  });

  it('existing map: deleteField is denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        assessment_verification_v1: trustedMap,
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        assessment_verification_v1: deleteField(),
      }),
    );
  });

  it('existing map: nested flow mutation is denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        assessment_verification_v1: trustedMap,
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        'assessment_verification_v1.flow': 'complete',
      }),
    );
  });

  it('existing map: nested property addition is denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        assessment_verification_v1: trustedMap,
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        'assessment_verification_v1.iq.status': 'verified',
      }),
    );
  });

  it('absent map: ordinary profile merge is allowed', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
        bio: 'legacy',
      });
    });
    await assertSucceeds(
      setDoc(
        doc(authedFirestore('userA'), 'users/userA'),
        { bio: 'legacy updated', profile_completed: true },
        { merge: true },
      ),
    );
  });

  it('absent map: client adding assessment_verification_v1 is denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        assessment_verification_v1: trustedMap,
      }),
    );
  });

  it('absent map: nested dot-path add is denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA'), {
        uid: 'userA',
        discover_eligible: false,
        active: true,
      });
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userA'), {
        'assessment_verification_v1.flow': 'complete',
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

describe('Entitlement rules (resonance_entitlement_firestore_schema_v1)', () => {
  const freeSnapshot = {
    uid: 'userA',
    tier: 'free',
    subscription_state: 'none',
    resonance_access: false,
    super_resonance_balance: 0,
    boost_balance: 0,
    schema_version: 'resonance_entitlement_firestore_schema_v1',
  };

  it('owner may GET own entitlements snapshot', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'entitlements/userA'), freeSnapshot);
    });
    await assertSucceeds(
      getDoc(doc(authedFirestore('userA'), 'entitlements/userA')),
    );
  });

  it('other user cannot GET entitlements snapshot', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'entitlements/userA'), freeSnapshot);
    });
    await assertFails(getDoc(doc(authedFirestore('userB'), 'entitlements/userA')));
  });

  it('client cannot create entitlements', async () => {
    await assertFails(
      setDoc(doc(authedFirestore('userA'), 'entitlements/userA'), {
        ...freeSnapshot,
        resonance_access: true,
        tier: 'resonance',
      }),
    );
  });

  it('client cannot update entitlements or balances', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'entitlements/userA'), freeSnapshot);
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'entitlements/userA'), {
        resonance_access: true,
        tier: 'resonance',
        subscription_state: 'active',
      }),
    );
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'entitlements/userA'), {
        super_resonance_balance: 99,
        boost_balance: 99,
      }),
    );
  });

  it('client cannot delete entitlements', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'entitlements/userA'), freeSnapshot);
    });
    await assertFails(
      deleteDoc(doc(authedFirestore('userA'), 'entitlements/userA')),
    );
  });

  it('client cannot list entitlements collection', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'entitlements/userA'), freeSnapshot);
    });
    await assertFails(getDocs(collection(authedFirestore('userA'), 'entitlements')));
  });

  it('purchase_ledger get denied for owner', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'entitlements', 'userA'), freeSnapshot);
      await setDoc(doc(db, 'entitlements', 'userA', 'purchase_ledger', 'txn1'), {
        uid: 'userA',
        ledger_id: 'txn1',
        event_type: 'consumable_purchase',
        effect: 'credit_boost',
      });
    });
    const db = authedFirestore('userA');
    await assertFails(
      getDoc(doc(db, 'entitlements', 'userA', 'purchase_ledger', 'txn1')),
    );
  });

  it('purchase_ledger list denied for owner', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'entitlements', 'userA'), freeSnapshot);
      await setDoc(doc(db, 'entitlements', 'userA', 'purchase_ledger', 'txn1'), {
        uid: 'userA',
        ledger_id: 'txn1',
      });
    });
    const db = authedFirestore('userA');
    await assertFails(
      getDocs(collection(db, 'entitlements', 'userA', 'purchase_ledger')),
    );
  });

  it('purchase_ledger write/delete denied for owner', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'entitlements', 'userA'), freeSnapshot);
      await setDoc(doc(db, 'entitlements', 'userA', 'purchase_ledger', 'txn1'), {
        uid: 'userA',
        ledger_id: 'txn1',
      });
    });
    const db = authedFirestore('userA');
    await assertFails(
      setDoc(doc(db, 'entitlements', 'userA', 'purchase_ledger', 'fake'), {
        effect: 'grant_resonance',
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'entitlements', 'userA', 'purchase_ledger', 'txn1'), {
        effect: 'noop',
      }),
    );
    await assertFails(
      deleteDoc(doc(db, 'entitlements', 'userA', 'purchase_ledger', 'txn1')),
    );
  });
});

describe('Discover Passport preference rules', () => {
  const path = 'users/userA/preferences/discover_passport_v1';
  const saved = {
    passport_enabled: true,
    passport_country: 'TR',
    passport_city: 'istanbul',
    schema_version: 'discover_passport_v1',
  };

  it('owner may GET own Passport preference', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), path), saved);
    });
    await assertSucceeds(getDoc(doc(authedFirestore('userA'), path)));
  });

  it('peer cannot GET Passport preference', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), path), saved);
    });
    await assertFails(getDoc(doc(authedFirestore('userB'), path)));
  });

  it('client cannot create/update/delete Passport preference', async () => {
    await assertFails(
      setDoc(doc(authedFirestore('userA'), path), saved),
    );
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), path), saved);
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), path), {
        passport_enabled: true,
        passport_city: 'berlin',
      }),
    );
    await assertFails(deleteDoc(doc(authedFirestore('userA'), path)));
  });

  it('client cannot list preferences', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), path), saved);
    });
    await assertFails(
      getDocs(collection(authedFirestore('userA'), 'users/userA/preferences')),
    );
  });
});

describe('FCM token rules', () => {
  const path = 'users/userA/fcm_tokens/abc123';
  const tokenDoc = {
    token: 'tok-1',
    platform: 'ios',
    app_id: 'app',
    apns_env: 'sandbox',
  };

  it('owner cannot get/list/create/update/delete fcm_tokens', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), path), tokenDoc);
    });
    const db = authedFirestore('userA');
    await assertFails(getDoc(doc(db, path)));
    await assertFails(getDocs(collection(db, 'users/userA/fcm_tokens')));
    await assertFails(setDoc(doc(db, path), tokenDoc));
    await assertFails(
      updateDoc(doc(db, path), { platform: 'android' }),
    );
    await assertFails(deleteDoc(doc(db, path)));
  });

  it('peer cannot read or write another user fcm_tokens', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), path), tokenDoc);
    });
    const db = authedFirestore('userB');
    await assertFails(getDoc(doc(db, path)));
    await assertFails(
      setDoc(doc(db, 'users/userA/fcm_tokens/hijack'), tokenDoc),
    );
    await assertFails(deleteDoc(doc(db, path)));
  });
});

describe('Push receipt rules', () => {
  const path = 'push_receipts/userA_userB_msg-1';
  const receipt = {
    type: 'message',
    thread_id: 'userA_userB',
    message_id: 'msg-1',
    recipient_uid: 'userB',
  };

  it('client cannot read or write push_receipts', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), path), receipt);
    });
    const db = authedFirestore('userA');
    await assertFails(getDoc(doc(db, path)));
    await assertFails(getDocs(collection(db, 'push_receipts')));
    await assertFails(setDoc(doc(db, path), receipt));
    await assertFails(deleteDoc(doc(db, path)));
  });
});

describe('Super Resonance signal rules (super_resonance_signal_v1)', () => {
  const signal = {
    from_uid: 'userA',
    to_uid: 'userB',
    status: 'active',
    spend_request_id: 'req-1',
    spend_ledger_id: 'unknown:spend:userA:req-1',
    schema_version: 'super_resonance_signal_v1',
  };

  it('client cannot read or write super_resonance_signals', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), 'super_resonance_signals/userA_userB'),
        signal,
      );
    });
    const db = authedFirestore('userA');
    await assertFails(
      getDoc(doc(db, 'super_resonance_signals/userA_userB')),
    );
    await assertFails(getDocs(collection(db, 'super_resonance_signals')));
    await assertFails(
      setDoc(doc(db, 'super_resonance_signals/userA_userC'), signal),
    );
    await assertFails(
      updateDoc(doc(db, 'super_resonance_signals/userA_userB'), {
        status: 'hidden',
      }),
    );
    await assertFails(
      deleteDoc(doc(db, 'super_resonance_signals/userA_userB')),
    );
  });
});

describe('public_profiles rules', () => {
  const eligiblePublic = {
    name: 'B',
    age: 28,
    discover_eligible: true,
    photos: ['https://example.com/b.jpg'],
    profile_photo_url: 'https://example.com/b.jpg',
  };

  async function seedPublicProfile(uid, data) {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `public_profiles/${uid}`), data);
    });
  }

  it('unauthenticated public profile GET denied', async () => {
    await seedPublicProfile('userB', eligiblePublic);
    await assertFails(
      getDoc(doc(unauthFirestore(), 'public_profiles/userB')),
    );
  });

  it('authenticated eligible stranger GET allowed', async () => {
    await seedPublicProfile('userB', eligiblePublic);
    await assertSucceeds(
      getDoc(doc(authedFirestore('userA'), 'public_profiles/userB')),
    );
  });

  it('authenticated ineligible stranger GET denied', async () => {
    await seedPublicProfile('userB', {
      ...eligiblePublic,
      discover_eligible: false,
    });
    await assertFails(
      getDoc(doc(authedFirestore('userA'), 'public_profiles/userB')),
    );
  });

  it('owner may GET own ineligible public profile', async () => {
    await seedPublicProfile('userA', {
      ...eligiblePublic,
      discover_eligible: false,
    });
    await assertSucceeds(
      getDoc(doc(authedFirestore('userA'), 'public_profiles/userA')),
    );
  });

  it('matched peer GET allowed when discover_eligible is false', async () => {
    await seedPublicProfile('userB', {
      ...eligiblePublic,
      discover_eligible: false,
    });
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'matches/userA_userB'), {
        users: ['userA', 'userB'],
        user_a: 'userA',
        user_b: 'userB',
        state: 'active',
      });
    });
    await assertSucceeds(
      getDoc(doc(authedFirestore('userA'), 'public_profiles/userB')),
    );
  });

  it('unmatched match does not allow GET of ineligible public profile', async () => {
    await seedPublicProfile('userB', {
      ...eligiblePublic,
      discover_eligible: false,
    });
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'matches/userA_userB'), {
        users: ['userA', 'userB'],
        user_a: 'userA',
        user_b: 'userB',
        state: 'unmatched',
      });
    });
    await assertFails(
      getDoc(doc(authedFirestore('userA'), 'public_profiles/userB')),
    );
  });

  it('blocked match does not allow GET of ineligible public profile', async () => {
    await seedPublicProfile('userB', {
      ...eligiblePublic,
      discover_eligible: false,
    });
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'matches/userA_userB'), {
        users: ['userA', 'userB'],
        user_a: 'userA',
        user_b: 'userB',
        state: 'blocked',
      });
    });
    await assertFails(
      getDoc(doc(authedFirestore('userA'), 'public_profiles/userB')),
    );
  });

  it('client create denied', async () => {
    await assertFails(
      setDoc(doc(authedFirestore('userA'), 'public_profiles/userA'), {
        name: 'A',
        discover_eligible: true,
      }),
    );
  });

  it('client update denied', async () => {
    await seedPublicProfile('userA', eligiblePublic);
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'public_profiles/userA'), {
        name: 'Hacked',
      }),
    );
  });

  it('client delete denied', async () => {
    await seedPublicProfile('userA', eligiblePublic);
    await assertFails(
      deleteDoc(doc(authedFirestore('userA'), 'public_profiles/userA')),
    );
  });

  it('eligible collection query allowed; unfiltered list denied', async () => {
    await seedPublicProfile('userB', eligiblePublic);
    await seedPublicProfile('userC', {
      ...eligiblePublic,
      name: 'C',
      discover_eligible: false,
    });

    await assertSucceeds(
      getDocs(
        query(
          collection(authedFirestore('userA'), 'public_profiles'),
          where('discover_eligible', '==', true),
        ),
      ),
    );
    await assertFails(
      getDocs(collection(authedFirestore('userA'), 'public_profiles')),
    );
    await assertFails(
      getDocs(collection(unauthFirestore(), 'public_profiles')),
    );
  });

  it('does not weaken users/{uid} peer get/list', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'users/userB'), {
        uid: 'userB',
        discover_eligible: false,
        email: 'secret@example.com',
      });
      await setDoc(doc(db, 'users/userC'), {
        uid: 'userC',
        discover_eligible: true,
        email: 'c@example.com',
      });
    });
    await assertFails(getDoc(doc(authedFirestore('userA'), 'users/userB')));
    await assertFails(getDoc(doc(authedFirestore('userA'), 'users/userC')));
  });
});

describe('users parent document lockdown', () => {
  async function seedUser(uid, extra) {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `users/${uid}`), {
        uid,
        name: uid,
        discover_eligible: false,
        ...extra,
      });
    });
  }

  it('A owner GET users/userA is allowed', async () => {
    await seedUser('userA', { discover_eligible: false });
    await assertSucceeds(getDoc(doc(authedFirestore('userA'), 'users/userA')));
  });

  it('B eligible stranger GET users/userB is denied', async () => {
    await seedUser('userB', { discover_eligible: true });
    await assertFails(getDoc(doc(authedFirestore('userA'), 'users/userB')));
  });

  it('C ineligible stranger GET users/userB is denied', async () => {
    await seedUser('userB', { discover_eligible: false });
    await assertFails(getDoc(doc(authedFirestore('userA'), 'users/userB')));
  });

  it('D active matched peer GET users/userB is denied', async () => {
    await seedUser('userB', { discover_eligible: false });
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'matches/userA_userB'), {
        users: ['userA', 'userB'],
        user_a: 'userA',
        user_b: 'userB',
        state: 'active',
      });
    });
    await assertFails(getDoc(doc(authedFirestore('userA'), 'users/userB')));
  });

  it('E authenticated users LIST is denied', async () => {
    await seedUser('userA', { discover_eligible: true });
    await seedUser('userB', { discover_eligible: true });
    await assertFails(getDocs(collection(authedFirestore('userA'), 'users')));
  });

  it('F filtered users discover_eligible query is denied', async () => {
    await seedUser('userB', { discover_eligible: true });
    await assertFails(
      getDocs(
        query(
          collection(authedFirestore('userA'), 'users'),
          where('discover_eligible', '==', true),
        ),
      ),
    );
  });

  it('G unauthenticated GET users/userB is denied', async () => {
    await seedUser('userB', { discover_eligible: true });
    await assertFails(getDoc(doc(unauthFirestore(), 'users/userB')));
  });

  it('H unauthenticated users LIST is denied', async () => {
    await seedUser('userB', { discover_eligible: true });
    await assertFails(getDocs(collection(unauthFirestore(), 'users')));
  });

  it('owner assessments GET still allowed after parent lock', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA/assessments/iq'), {
        answers: { q1: 'own' },
      });
    });
    await assertSucceeds(
      getDoc(doc(authedFirestore('userA'), 'users/userA/assessments/iq')),
    );
  });

  it('owner blocks GET still allowed after parent lock', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA/blocks/userB'), {
        blocked_uid: 'userB',
      });
    });
    await assertSucceeds(
      getDoc(doc(authedFirestore('userA'), 'users/userA/blocks/userB')),
    );
  });

  it('owner swipes GET still allowed after parent lock', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userA/swipes/userB'), {
        direction: 'pass',
      });
    });
    await assertSucceeds(
      getDoc(doc(authedFirestore('userA'), 'users/userA/swipes/userB')),
    );
  });

  it('owner Passport preference GET still allowed after parent lock', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), 'users/userA/preferences/discover_passport_v1'),
        {
          passport_enabled: false,
          schema_version: 'discover_passport_v1',
        },
      );
    });
    await assertSucceeds(
      getDoc(
        doc(
          authedFirestore('userA'),
          'users/userA/preferences/discover_passport_v1',
        ),
      ),
    );
  });

  it('reverse swipe GET by target is denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/userB/swipes/userA'), {
        direction: 'like',
        from_uid: 'userB',
        target_uid: 'userA',
      });
    });
    await assertFails(
      getDoc(doc(authedFirestore('userA'), 'users/userB/swipes/userA')),
    );
  });
});

describe('swipe reverse-read lockdown', () => {
  async function seedSwipe(fromUid, targetUid, data) {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `users/${fromUid}/swipes/${targetUid}`), {
        from_uid: fromUid,
        target_uid: targetUid,
        ...data,
      });
    });
  }

  it('target cannot GET existing inbound Like', async () => {
    await seedSwipe('userA', 'userB', {
      direction: 'like',
      from_uid: 'userA',
      target_uid: 'userB',
    });
    await assertFails(
      getDoc(doc(authedFirestore('userB'), 'users/userA/swipes/userB')),
    );
  });

  it('target cannot GET existing inbound Pass', async () => {
    await seedSwipe('userA', 'userB', { direction: 'pass' });
    await assertFails(
      getDoc(doc(authedFirestore('userB'), 'users/userA/swipes/userB')),
    );
  });

  it('target GET of missing swipe is permission-denied', async () => {
    await assertFails(
      getDoc(doc(authedFirestore('userB'), 'users/userA/swipes/userB')),
    );
  });

  it('owner GET own swipe is allowed', async () => {
    await seedSwipe('userA', 'userB', { direction: 'pass' });
    await assertSucceeds(
      getDoc(doc(authedFirestore('userA'), 'users/userA/swipes/userB')),
    );
  });

  it('owner LIST own swipes is allowed', async () => {
    await seedSwipe('userA', 'userB', { direction: 'pass' });
    await seedSwipe('userA', 'userC', { direction: 'like' });
    await assertSucceeds(
      getDocs(collection(authedFirestore('userA'), 'users/userA/swipes')),
    );
  });

  it('owner client Pass CREATE is allowed', async () => {
    await assertSucceeds(
      setDoc(doc(authedFirestore('userA'), 'users/userA/swipes/userB'), {
        from_uid: 'userA',
        target_uid: 'userB',
        direction: 'pass',
        source: 'discover',
      }),
    );
  });

  it('owner existing Pass to Pass UPDATE is allowed', async () => {
    await seedSwipe('userA', 'userB', {
      direction: 'pass',
      source: 'discover',
    });
    await assertSucceeds(
      updateDoc(doc(authedFirestore('userA'), 'users/userA/swipes/userB'), {
        direction: 'pass',
        source: 'discover',
      }),
    );
  });

  it('owner client Like CREATE is denied', async () => {
    await assertFails(
      setDoc(doc(authedFirestore('userA'), 'users/userA/swipes/userB'), {
        from_uid: 'userA',
        target_uid: 'userB',
        direction: 'like',
        source: 'discover',
      }),
    );
  });

  it('owner cannot downgrade Admin Like to Pass', async () => {
    await seedSwipe('userA', 'userB', {
      direction: 'like',
      source: 'discover',
    });
    await assertFails(
      updateDoc(doc(authedFirestore('userA'), 'users/userA/swipes/userB'), {
        direction: 'pass',
      }),
    );
  });

  it('client swipe DELETE is denied', async () => {
    await seedSwipe('userA', 'userB', { direction: 'pass' });
    await assertFails(
      deleteDoc(doc(authedFirestore('userA'), 'users/userA/swipes/userB')),
    );
    await assertFails(
      deleteDoc(doc(authedFirestore('userB'), 'users/userA/swipes/userB')),
    );
  });

  it('peer LIST of another user swipes is denied', async () => {
    await seedSwipe('userA', 'userB', { direction: 'like' });
    await seedSwipe('userA', 'userC', { direction: 'pass' });
    await assertFails(
      getDocs(collection(authedFirestore('userB'), 'users/userA/swipes')),
    );
  });

  it('inbound collection-group swipe query is denied', async () => {
    await seedSwipe('userA', 'userB', {
      direction: 'like',
      target_uid: 'userB',
    });
    await assertFails(
      getDocs(
        query(
          collectionGroup(authedFirestore('userB'), 'swipes'),
          where('target_uid', '==', 'userB'),
        ),
      ),
    );
  });
});

describe('Chat image Firestore rules', () => {
  const pair = 'userA_userB';

  async function seedActiveChat() {
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

  function validImageMessage(overrides = {}) {
    return {
      sender_id: 'userA',
      type: 'image',
      text: '',
      image_url:
        'https://firebasestorage.googleapis.com/v0/b/demo-qmatch.appspot.com/o/chat_media%2FuserA_userB%2FuserA%2Fphoto.jpg?alt=media',
      image_storage_path: 'chat_media/userA_userB/userA/photo.jpg',
      ...overrides,
    };
  }

  it('active participant can create valid image message', async () => {
    await seedActiveChat();

    await assertSucceeds(
      setDoc(
        doc(
          authedFirestore('userA'),
          `threads/${pair}/messages/image-valid`,
        ),
        validImageMessage(),
      ),
    );
  });

  it('image message cannot claim another user storage path', async () => {
    await seedActiveChat();

    await assertFails(
      setDoc(
        doc(
          authedFirestore('userA'),
          `threads/${pair}/messages/image-wrong-owner`,
        ),
        validImageMessage({
          image_storage_path: `chat_media/${pair}/userB/photo.jpg`,
        }),
      ),
    );
  });

  it('image message rejects non-Firebase image URL', async () => {
    await seedActiveChat();

    await assertFails(
      setDoc(
        doc(
          authedFirestore('userA'),
          `threads/${pair}/messages/image-external-url`,
        ),
        validImageMessage({
          image_url: 'https://example.com/photo.jpg',
        }),
      ),
    );
  });

  it('non-participant cannot create image message', async () => {
    await seedActiveChat();

    await assertFails(
      setDoc(
        doc(
          authedFirestore('userC'),
          `threads/${pair}/messages/image-outsider`,
        ),
        {
          ...validImageMessage(),
          sender_id: 'userC',
          image_storage_path: `chat_media/${pair}/userC/photo.jpg`,
        },
      ),
    );
  });

  it('closed conversation rejects image message', async () => {
    await seedActiveChat();

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), `threads/${pair}`), {
        status: 'closed',
      });
    });

    await assertFails(
      setDoc(
        doc(
          authedFirestore('userA'),
          `threads/${pair}/messages/image-closed`,
        ),
        validImageMessage(),
      ),
    );
  });
});

describe('Chat media Storage rules', () => {
  const pair = 'userA_userB';
  const smallJpeg = Uint8Array.from([0xff, 0xd8, 0xff, 0xd9]);

  async function seedActiveChat() {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();

      await setDoc(doc(db, `matches/${pair}`), {
        users: ['userA', 'userB'],
        state: 'active',
        thread_id: pair,
      });

      await setDoc(doc(db, `threads/${pair}`), {
        participants: ['userA', 'userB'],
        status: 'active',
        match_id: pair,
      });
    });
  }

  it('active participant can upload to own chat media path', async () => {
    await seedActiveChat();

    const r = ref(
      authedStorage('userA'),
      `chat_media/${pair}/userA/photo.jpg`,
    );

    await assertSucceeds(
      uploadBytes(r, smallJpeg, { contentType: 'image/jpeg' }),
    );
  });

  it('participant cannot upload to peer UID path', async () => {
    await seedActiveChat();

    const r = ref(
      authedStorage('userA'),
      `chat_media/${pair}/userB/photo.jpg`,
    );

    await assertFails(
      uploadBytes(r, smallJpeg, { contentType: 'image/jpeg' }),
    );
  });

  it('non-participant cannot upload chat media', async () => {
    await seedActiveChat();

    const r = ref(
      authedStorage('userC'),
      `chat_media/${pair}/userC/photo.jpg`,
    );

    await assertFails(
      uploadBytes(r, smallJpeg, { contentType: 'image/jpeg' }),
    );
  });

  it('chat media rejects invalid content type', async () => {
    await seedActiveChat();

    const r = ref(
      authedStorage('userA'),
      `chat_media/${pair}/userA/file.bin`,
    );

    await assertFails(
      uploadBytes(r, smallJpeg, {
        contentType: 'application/octet-stream',
      }),
    );
  });

  it('chat media rejects oversized image', async () => {
    await seedActiveChat();

    const big = new Uint8Array(8 * 1024 * 1024 + 1);

    const r = ref(
      authedStorage('userA'),
      `chat_media/${pair}/userA/too-big.jpg`,
    );

    await assertFails(
      uploadBytes(r, big, { contentType: 'image/jpeg' }),
    );
  });

  it('closed conversation rejects new chat media upload', async () => {
    await seedActiveChat();

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), `threads/${pair}`), {
        status: 'closed',
      });
    });

    const r = ref(
      authedStorage('userA'),
      `chat_media/${pair}/userA/closed.jpg`,
    );

    await assertFails(
      uploadBytes(r, smallJpeg, { contentType: 'image/jpeg' }),
    );
  });

  it('inactive match rejects new chat media upload', async () => {
    await seedActiveChat();

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), `matches/${pair}`), {
        state: 'unmatched',
      });
    });

    const r = ref(
      authedStorage('userA'),
      `chat_media/${pair}/userA/inactive.jpg`,
    );

    await assertFails(
      uploadBytes(r, smallJpeg, { contentType: 'image/jpeg' }),
    );
  });

  it('both participants may read existing chat media but outsider may not', async () => {
    await seedActiveChat();

    const path = `chat_media/${pair}/userA/history.jpg`;

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await uploadBytes(ref(ctx.storage(), path), smallJpeg, {
        contentType: 'image/jpeg',
      });

      await updateDoc(doc(ctx.firestore(), `threads/${pair}`), {
        status: 'closed',
      });
    });

    await assertSucceeds(
      getBytes(ref(authedStorage('userA'), path)),
    );

    await assertSucceeds(
      getBytes(ref(authedStorage('userB'), path)),
    );

    await assertFails(
      getBytes(ref(authedStorage('userC'), path)),
    );

    await assertFails(
      getBytes(ref(unauthStorage(), path)),
    );
  });

  it('existing chat media cannot be overwritten', async () => {
    await seedActiveChat();

    const path = `chat_media/${pair}/userA/immutable.jpg`;

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await uploadBytes(ref(ctx.storage(), path), smallJpeg, {
        contentType: 'image/jpeg',
      });
    });

    await assertFails(
      uploadBytes(
        ref(authedStorage('userA'), path),
        smallJpeg,
        { contentType: 'image/jpeg' },
      ),
    );
  });

  it('only path owner can delete chat media', async () => {
    await seedActiveChat();

    const path = `chat_media/${pair}/userA/delete-me.jpg`;

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await uploadBytes(ref(ctx.storage(), path), smallJpeg, {
        contentType: 'image/jpeg',
      });
    });

    await assertFails(
      deleteObject(ref(authedStorage('userB'), path)),
    );

    await assertSucceeds(
      deleteObject(ref(authedStorage('userA'), path)),
    );
  });
});
