import '../../iap/domain/qmatch_iap_product_ids.dart';
import '../../iap/services/entitlement_repository.dart';
import '../../iap/services/ios_iap_client.dart';
import '../domain/super_resonance_send_result.dart';
import 'super_resonance_send_client.dart';

/// Discover Super Resonance send + consumable purchase.
///
/// Balance is trusted `entitlements/{uid}` only. Never inferred from StoreKit.
class DiscoverSuperResonanceController {
  DiscoverSuperResonanceController({
    EntitlementRepository? entitlements,
    SuperResonanceSendClient? sendClient,
    IosIapClient? iapClient,
    String? Function()? uidProvider,
    Future<int> Function()? readBalanceOverride,
    Future<SuperResonanceSendResult> Function(String targetUid, String requestId)?
        sendOverride,
    Future<int> Function()? purchaseOverride,
  })  : _entitlements = entitlements ?? EntitlementRepository(),
        _sendClient = sendClient ?? SuperResonanceSendClient(),
        _iapClient = iapClient,
        _uidProvider = uidProvider,
        _readBalanceOverride = readBalanceOverride,
        _sendOverride = sendOverride,
        _purchaseOverride = purchaseOverride;

  final EntitlementRepository _entitlements;
  final SuperResonanceSendClient _sendClient;
  final IosIapClient? _iapClient;
  final String? Function()? _uidProvider;
  final Future<int> Function()? _readBalanceOverride;
  final Future<SuperResonanceSendResult> Function(
    String targetUid,
    String requestId,
  )? _sendOverride;
  final Future<int> Function()? _purchaseOverride;

  static const productId = QmatchIapProductIds.superResonanceX1;

  /// Trusted balance. Unreadable / missing uid → 0 (fail closed).
  Future<int> readTrustedBalance() async {
    final custom = _readBalanceOverride;
    if (custom != null) {
      try {
        return _clampBalance(await custom());
      } catch (_) {
        return 0;
      }
    }
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

  /// Purchase `qmatch.super_resonance.x1`, then return trusted balance.
  /// Does not send Super Resonance.
  Future<int> purchaseThenReadBalance() async {
    final custom = _purchaseOverride;
    if (custom != null) {
      return _clampBalance(await custom());
    }
    final iap = _iapClient;
    if (iap == null) {
      return readTrustedBalance();
    }
    final result = await iap.purchase(productId);
    return _clampBalance(result.entitlement.superResonanceBalance);
  }

  static int _clampBalance(int value) => value < 0 ? 0 : value;
}
