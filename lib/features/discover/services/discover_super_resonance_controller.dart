import '../../../core/debug/qmatch_perf.dart';
import '../../iap/domain/qmatch_iap_product_ids.dart';
import '../../iap/services/entitlement_repository.dart';
import '../../iap/services/ios_iap_client.dart';
import '../domain/super_resonance_availability.dart';
import '../domain/super_resonance_send_result.dart';
import 'super_resonance_send_client.dart';

/// Discover Super Resonance send + consumable purchase.
///
/// Purchased balance is trusted `entitlements/{uid}.super_resonance_balance`.
/// Daily remaining comes from trusted backend server time only.
class DiscoverSuperResonanceController {
  DiscoverSuperResonanceController({
    EntitlementRepository? entitlements,
    SuperResonanceSendClient? sendClient,
    IosIapClient? iapClient,
    String? Function()? uidProvider,
    Future<int> Function()? readBalanceOverride,
    Future<SuperResonanceAvailability> Function()? readAvailabilityOverride,
    Future<SuperResonanceSendResult> Function(
            String targetUid, String requestId)?
        sendOverride,
    Future<int> Function()? purchaseOverride,
    Future<String?> Function()? localizedPriceOverride,
  })  : _entitlements = entitlements ?? EntitlementRepository(),
        _sendClient = sendClient ?? SuperResonanceSendClient(),
        _iapClient = iapClient,
        _uidProvider = uidProvider,
        _readBalanceOverride = readBalanceOverride,
        _readAvailabilityOverride = readAvailabilityOverride,
        _sendOverride = sendOverride,
        _purchaseOverride = purchaseOverride,
        _localizedPriceOverride = localizedPriceOverride;

  final EntitlementRepository _entitlements;
  final SuperResonanceSendClient _sendClient;
  final IosIapClient? _iapClient;
  final String? Function()? _uidProvider;
  final Future<int> Function()? _readBalanceOverride;
  final Future<SuperResonanceAvailability> Function()?
      _readAvailabilityOverride;
  final Future<SuperResonanceSendResult> Function(
    String targetUid,
    String requestId,
  )? _sendOverride;
  final Future<int> Function()? _purchaseOverride;
  final Future<String?> Function()? _localizedPriceOverride;

  static const productId = QmatchIapProductIds.superResonanceX1;

  /// Total currently usable Super Resonance (daily remaining + purchased).
  Future<int> readTrustedBalance() async {
    final availability = await readTrustedAvailability();
    return availability.totalAvailable;
  }

  /// Trusted availability. Fail-closed daily remaining if the callable fails.
  Future<SuperResonanceAvailability> readTrustedAvailability() {
    return QmatchPerf.trace('super_resonance.availability', () async {
      final customAvailability = _readAvailabilityOverride;
      if (customAvailability != null) {
        try {
          return _clampAvailability(await customAvailability());
        } catch (_) {
          return SuperResonanceAvailability.empty;
        }
      }
      final customBalance = _readBalanceOverride;
      if (customBalance != null) {
        try {
          final purchased = _clampBalance(await customBalance());
          return SuperResonanceAvailability(
            dailyRemaining: 0,
            dailyLimit: 0,
            purchasedBalance: purchased,
            totalAvailable: purchased,
          );
        } catch (_) {
          return SuperResonanceAvailability.empty;
        }
      }
      try {
        return _clampAvailability(await _sendClient.availability());
      } catch (_) {
        final purchased = await _readPurchasedBalance();
        return SuperResonanceAvailability(
          dailyRemaining: 0,
          dailyLimit: 0,
          purchasedBalance: purchased,
          totalAvailable: purchased,
        );
      }
    });
  }

  Future<int> _readPurchasedBalance() async {
    try {
      final uid = _uidProvider?.call();
      if (uid == null || uid.isEmpty) return 0;
      final snap = await _entitlements.fetch(uid);
      return _clampBalance(snap.superResonanceBalance);
    } catch (_) {
      return 0;
    }
  }

  Future<SuperResonanceSendResult> send({
    required String targetUid,
    String? requestId,
  }) {
    final id = (requestId == null || requestId.trim().isEmpty)
        ? _sendClient.newRequestId()
        : requestId.trim();
    final custom = _sendOverride;
    if (custom != null) return custom(targetUid, id);
    return _sendClient.send(targetUid: targetUid, requestId: id);
  }

  /// Purchase Super Resonance x1, then re-read trusted availability.
  /// Does not send Super Resonance. Never infers balance from StoreKit.
  Future<int> purchaseThenReadBalance() async {
    final custom = _purchaseOverride;
    if (custom != null) {
      await custom();
      return readTrustedBalance();
    }
    final iap = _iapClient;
    if (iap == null) {
      return readTrustedBalance();
    }
    await iap.purchase(productId);
    return readTrustedBalance();
  }

  /// Localized StoreKit price for Super Resonance. Missing / failed → null.
  /// Never returns the internal product id.
  Future<String?> loadLocalizedPrice() async {
    final custom = _localizedPriceOverride;
    if (custom != null) {
      try {
        final price = await custom();
        return _publicPrice(price);
      } catch (_) {
        return null;
      }
    }
    final iap = _iapClient;
    if (iap == null) return null;
    try {
      final products = await iap.loadProducts();
      for (final product in products) {
        if (product.id != productId) continue;
        return _publicPrice(product.price);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static int _clampBalance(int value) => value < 0 ? 0 : value;

  static SuperResonanceAvailability _clampAvailability(
    SuperResonanceAvailability value,
  ) {
    final daily = _clampBalance(value.dailyRemaining);
    final limit = _clampBalance(value.dailyLimit);
    final purchased = _clampBalance(value.purchasedBalance);
    return SuperResonanceAvailability(
      dailyRemaining: daily,
      dailyLimit: limit,
      purchasedBalance: purchased,
      totalAvailable: daily + purchased,
    );
  }

  static String? _publicPrice(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed == productId) return null;
    if (trimmed.contains('qmatch.super_resonance')) return null;
    return trimmed;
  }
}
