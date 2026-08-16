import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only first-use Discover guidance: holographic tutorial + swipe stamps.
///
/// Not synced. Does not touch ranking, swipes, or Firestore.
class DiscoverGestureOnboardingStore {
  DiscoverGestureOnboardingStore({
    SharedPreferences? prefs,
    this.viewerUid,
  }) : _prefs = prefs;

  static const seenKeyPrefix = 'qmatch_discover_gesture_onboarding_seen_v1';
  static const swipeCountKeyPrefix =
      'qmatch_discover_first_swipe_stamps_count_v1';
  static const swipeStampLimit = 3;

  /// Bumped when debug replay resets guidance so a kept-alive DiscoverScreen
  /// can re-read prefs without waiting on IndexedStack visibility.
  static final ValueNotifier<int> guidanceRevision = ValueNotifier<int>(0);

  final String? viewerUid;
  SharedPreferences? _prefs;

  String get storageKey {
    final uid = viewerUid;
    if (uid == null || uid.isEmpty) return seenKeyPrefix;
    return '${seenKeyPrefix}_$uid';
  }

  String get swipeCountStorageKey {
    final uid = viewerUid;
    if (uid == null || uid.isEmpty) return swipeCountKeyPrefix;
    return '${swipeCountKeyPrefix}_$uid';
  }

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> hasSeen() async {
    final prefs = await _ensure();
    return prefs.getBool(storageKey) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = await _ensure();
    await prefs.setBool(storageKey, true);
  }

  /// Debug / tests only. Production first-visit flow never calls this.
  Future<void> clearSeen() async {
    final prefs = await _ensure();
    await prefs.remove(storageKey);
    notifyGuidanceChanged();
  }

  Future<int> committedSwipeCount() async {
    final prefs = await _ensure();
    return prefs.getInt(swipeCountStorageKey) ?? 0;
  }

  Future<int> recordCommittedSwipe() async {
    final prefs = await _ensure();
    final next = (prefs.getInt(swipeCountStorageKey) ?? 0) + 1;
    await prefs.setInt(swipeCountStorageKey, next);
    return next;
  }

  Future<void> resetCommittedSwipeCount() async {
    final prefs = await _ensure();
    await prefs.remove(swipeCountStorageKey);
  }

  /// Debug replay: hologram unseen + stamps available for the next 3 swipes.
  Future<void> resetFirstUseGuidance() async {
    final prefs = await _ensure();
    await prefs.remove(storageKey);
    await prefs.remove(swipeCountStorageKey);
    notifyGuidanceChanged();
  }

  static bool showSwipeStamps(int committedCount) =>
      committedCount < swipeStampLimit;

  static void notifyGuidanceChanged() {
    guidanceRevision.value++;
  }
}
