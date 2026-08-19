import 'iap_exceptions.dart';

/// User-facing purchase/verify outcome. Cancel is not an error kind.
enum QmatchPurchaseErrorKind {
  resonanceSubscription,
  superResonanceConsumable,
  verification,
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
  return productFailure;
}
