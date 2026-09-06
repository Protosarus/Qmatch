/**
 * Trusted account deletion callable.
 *
 * Auth required. Never uses client targetUid. Unverified password accounts
 * may delete themselves (no Phase 4 product-verification gate).
 */

'use strict';

const { HttpsError } = require('firebase-functions/v2/https');
const {
  CALLABLE_NAME,
  resolveDeletionUid,
} = require('./delete_qmatch_account');
const { runDeleteQMatchAccount } = require('./delete_qmatch_account_runner');

function handleDeleteQMatchAccount(deps = {}) {
  return async (request) => {
    let uid;
    try {
      uid = resolveDeletionUid(request);
    } catch (err) {
      throw new HttpsError(
        'unauthenticated',
        'Authentication required to delete this account.',
      );
    }

    try {
      return await runDeleteQMatchAccount(uid, {
        ...deps,
        requestData: request && request.data,
      });
    } catch (err) {
      if (err && err.code === 'failed-precondition') {
        throw new HttpsError(
          'failed-precondition',
          'Apple authorization must be revoked before deletion.',
          err.details || { code: 'apple_revocation_required' },
        );
      }
      if (err && err.code === 'unauthenticated') {
        throw new HttpsError(
          'unauthenticated',
          'Authentication required to delete this account.',
        );
      }
      throw new HttpsError(
        'internal',
        'Account deletion could not be completed. Try again.',
      );
    }
  };
}

module.exports = {
  CALLABLE_NAME,
  handleDeleteQMatchAccount,
};
