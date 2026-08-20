import 'iap_exceptions.dart';

/// User-facing purchase/verify outcome. Cancel is not an error kind.
enum QmatchPurchaseErrorKind {
  resonanceSubscription,
  superResonanceConsumable,
  verification,
  alreadyOwned,
}

/// Maps an IAP exception to presentation. Cancel → null (silent).
QmatchPurchaseErrorKind? classifyPurchaseException(
  Object error, {
  required QmatchPurchaseErrorKind productFailure,
}) {
  if (error is IapPurchaseCanceledException) return null;
  if (error is IapVerificationFailedException) {
    return QmatchPurchaseErrorKind.verification;
  }
  if (productFailure == QmatchPurchaseErrorKind.resonanceSubscription &&
      looksLikeAlreadyOwnedStoreError(error)) {
    return QmatchPurchaseErrorKind.alreadyOwned;
  }
  return productFailure;
}

/// True only for explicit already-owned / already-subscribed store signals.
///
/// Generic StoreKit failures (`purchase_error`, `SKErrorDomain`, timeouts)
/// are not classified. Numeric Play Billing `7` is not used alone — it
/// collides with unrelated SKError codes.
bool looksLikeAlreadyOwnedStoreError(Object error) {
  if (error is! IapPurchaseFailedException) return false;
  final code = (error.storeCode ?? '').trim().toLowerCase();
  if (code == 'itemalreadyowned' || code == 'item_already_owned') {
    return true;
  }
  final haystack =
      '${error.message} ${error.storeDetails ?? ''} ${error.storeCode ?? ''}'
          .toLowerCase();
  const markers = [
    'already been bought',
    'already purchased',
    'already subscribed',
    'currently subscribed',
    'item already owned',
  ];
  return markers.any(haystack.contains);
}
