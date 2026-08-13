/**
 * Google Play Developer API client (androidpublisher).
 */

'use strict';

const { google } = require('googleapis');
const { loadPlayIapConfig } = require('./play_iap_config');

/**
 * @param {object} config
 * @returns {Promise<import('googleapis').androidpublisher_v3.Androidpublisher>}
 */
async function createPlayAndroidPublisher(config) {
  let auth;
  if (config.credentialsPath) {
    auth = new google.auth.GoogleAuth({
      keyFile: config.credentialsPath,
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });
  } else {
    auth = new google.auth.JWT({
      email: config.clientEmail,
      key: config.privateKey,
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });
  }
  return google.androidpublisher({ version: 'v3', auth });
}

/**
 * Build Play API helpers from config or return not configured.
 * @param {object} [opts]
 * @returns {Promise<{ ok: true, helpers: object, config: object }|{ ok: false }>}
 */
async function resolvePlayApiHelpers(opts = {}) {
  if (
    typeof opts.fetchSubscription === 'function' ||
    typeof opts.fetchProductPurchase === 'function'
  ) {
    const creds = opts.credentials;
    if (
      !(
        creds &&
        (creds.configured || creds.clientEmail || creds.privateKey)
      )
    ) {
      return { ok: false };
    }
    return {
      ok: true,
      config: {
        packageName:
          (opts.packageName ||
            (opts.env && opts.env.PLAY_IAP_PACKAGE_NAME) ||
            'com.qmatch.app'),
        requireAccountBinding: opts.requireBinding !== false,
      },
      helpers: {
        fetchSubscription: opts.fetchSubscription,
        fetchProductPurchase: opts.fetchProductPurchase,
        acknowledgeSubscription: opts.acknowledgeSubscription,
        acknowledgeProduct: opts.acknowledgeProduct,
        consumeProduct: opts.consumeProduct,
      },
    };
  }

  const loaded = loadPlayIapConfig(opts.env || process.env);
  if (!loaded.ok) {
    return { ok: false };
  }

  try {
    const androidpublisher = opts.androidpublisher
      ? opts.androidpublisher
      : await createPlayAndroidPublisher(loaded.config);
    const packageName = loaded.config.packageName;

    return {
      ok: true,
      config: loaded.config,
      helpers: {
        async fetchSubscription({ purchaseToken }) {
          const res = await androidpublisher.purchases.subscriptionsv2.get({
            packageName,
            token: purchaseToken,
          });
          return res.data;
        },
        async fetchProductPurchase({ purchaseToken, productId }) {
          const res = await androidpublisher.purchases.products.get({
            packageName,
            productId,
            token: purchaseToken,
          });
          return res.data;
        },
        async acknowledgeSubscription({ purchaseToken, productId }) {
          await androidpublisher.purchases.subscriptions.acknowledge({
            packageName,
            subscriptionId: productId || 'qmatch.resonance',
            token: purchaseToken,
            requestBody: {},
          });
        },
        async acknowledgeProduct({ purchaseToken, productId }) {
          await androidpublisher.purchases.products.acknowledge({
            packageName,
            productId,
            token: purchaseToken,
            requestBody: {},
          });
        },
        async consumeProduct({ purchaseToken, productId }) {
          await androidpublisher.purchases.products.consume({
            packageName,
            productId,
            token: purchaseToken,
          });
        },
      },
    };
  } catch (_err) {
    return { ok: false };
  }
}

module.exports = {
  createPlayAndroidPublisher,
  resolvePlayApiHelpers,
};
