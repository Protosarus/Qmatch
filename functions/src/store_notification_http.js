/**
 * HTTP entrypoints for store notifications (ASSN v2 / RTDN).
 * Not deployed by this change — handlers are unit-tested.
 */

'use strict';

const {
  handleAppleAssnNotification,
} = require('./store_notification_apple');
const {
  handlePlayRtdnNotification,
} = require('./store_notification_play');

/**
 * Express-style request handler for Apple ASSN.
 * @param {object} req
 * @param {object} res
 * @param {object} [deps]
 */
async function appleAssnHttpHandler(req, res, deps = {}) {
  try {
    const body = req.body || {};
    const signedPayload = body.signedPayload || body.signed_payload;
    const result = await handleAppleAssnNotification(
      { signedPayload },
      deps.appleNotification || deps,
    );
    const status =
      result.code === 'invalid_jws' || result.code === 'verification_not_configured'
        ? 400
        : 200;
    res.status(status).json(result);
  } catch (_err) {
    res.status(500).json({ ok: false, code: 'internal' });
  }
}

/**
 * Express-style request handler for Play RTDN Pub/Sub push.
 * @param {object} req
 * @param {object} res
 * @param {object} [deps]
 */
async function playRtdnHttpHandler(req, res, deps = {}) {
  try {
    const result = await handlePlayRtdnNotification(req.body || {}, {
      play: deps.play,
      db: deps.db,
      playFinalizeHelpers: deps.playFinalizeHelpers,
    });
    const status =
      result.code === 'invalid_message' ||
      result.code === 'verification_not_configured'
        ? 400
        : 200;
    // Always 200 for unknown_uid after auth parse so Pub/Sub does not infinite-retry
    // poison messages — return 200 with fail-closed body except config/parse errors.
    if (result.code === 'unknown_uid' || result.code === 'product_not_allowed') {
      res.status(200).json(result);
      return;
    }
    res.status(status).json(result);
  } catch (_err) {
    res.status(500).json({ ok: false, code: 'internal' });
  }
}

module.exports = {
  appleAssnHttpHandler,
  playRtdnHttpHandler,
};
