/// Fail-closed IAP / entitlement errors. Never imply local premium grant.
class IapException implements Exception {
  IapException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'IapException($code): $message';
}

class IapAuthRequiredException extends IapException {
  IapAuthRequiredException()
      : super('auth_required', 'Firebase authentication is required for IAP.');
}

class IapPlatformDisabledException extends IapException {
  IapPlatformDisabledException(String platform)
      : super(
          'platform_disabled',
          'IAP purchases are not configured for $platform.',
        );
}

class IapStoreUnavailableException extends IapException {
  IapStoreUnavailableException([String? detail])
      : super(
          'store_unavailable',
          detail ?? 'StoreKit is unavailable on this device.',
        );
}

class IapProductUnavailableException extends IapException {
  IapProductUnavailableException(String productId)
      : super(
          'product_unavailable',
          'StoreKit product not found: $productId',
        );
}

class IapPurchaseCanceledException extends IapException {
  IapPurchaseCanceledException()
      : super('purchase_canceled', 'User canceled the purchase.');
}

class IapPurchaseFailedException extends IapException {
  IapPurchaseFailedException(
    String detail, {
    this.storeCode,
    this.storeDetails,
  }) : super('purchase_failed', detail);

  /// StoreKit / Play Billing [IAPError.code] when the failure came from a
  /// purchase update. Never used to grant entitlement.
  final String? storeCode;

  /// Stringified [IAPError.details] (e.g. SKError userInfo). UX only.
  final String? storeDetails;
}

/// Verification / restore failed — do not grant access locally.
class IapVerificationFailedException extends IapException {
  IapVerificationFailedException({
    required String code,
    String? message,
    this.response,
  }) : super(
          code,
          message ??
              'Purchase verification failed. Entitlement not granted locally.',
        );

  final Map<String, dynamic>? response;
}
