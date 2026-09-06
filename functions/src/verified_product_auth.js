/**
 * Provider-aware product-auth guard for callable Functions.
 *
 * Firebase ID-token claims are the authority. A client-written Firestore
 * `email_verified` field is never consulted.
 *
 * PASSWORD: require token.email_verified === true
 * PHONE / GOOGLE / APPLE / missing provider: not gated by this policy
 */

'use strict';

const { HttpsError } = require('firebase-functions/v2/https');

const PASSWORD_PROVIDER = 'password';
const PHONE_PROVIDER = 'phone';
const GOOGLE_PROVIDER = 'google.com';
const APPLE_PROVIDER = 'apple.com';
const EMAIL_VERIFICATION_REQUIRED = 'email_verification_required';

function authToken(auth) {
  return auth && auth.token && typeof auth.token === 'object' ? auth.token : {};
}

function signInProviderFromAuth(auth) {
  const firebase = authToken(auth).firebase;
  if (!firebase || typeof firebase !== 'object') return '';
  const provider = firebase.sign_in_provider;
  return typeof provider === 'string' ? provider.trim() : '';
}

function isPasswordProvider(auth) {
  return signInProviderFromAuth(auth) === PASSWORD_PROVIDER;
}

function isEmailVerifiedClaim(auth) {
  return authToken(auth).email_verified === true;
}

/**
 * True only for an unverified password sign-in.
 * Presence of an email address is not used.
 */
function requiresEmailVerification(auth) {
  return isPasswordProvider(auth) && !isEmailVerifiedClaim(auth);
}

function requireVerifiedProductUid(request, unauthenticatedMessage) {
  const auth = request && request.auth;
  const uid = auth && auth.uid;
  if (!uid) {
    throw new HttpsError(
      'unauthenticated',
      unauthenticatedMessage || 'Authentication required.',
    );
  }
  if (requiresEmailVerification(auth)) {
    throw new HttpsError(
      'permission-denied',
      'Email verification required.',
      { code: EMAIL_VERIFICATION_REQUIRED },
    );
  }
  return uid;
}

module.exports = {
  PASSWORD_PROVIDER,
  PHONE_PROVIDER,
  GOOGLE_PROVIDER,
  APPLE_PROVIDER,
  EMAIL_VERIFICATION_REQUIRED,
  signInProviderFromAuth,
  isPasswordProvider,
  isEmailVerifiedClaim,
  requiresEmailVerification,
  requireVerifiedProductUid,
};
