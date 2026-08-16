import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../services/discover_gesture_onboarding_store.dart';

/// Re-reads the local gesture-tutorial seen flag when this subtree becomes
/// visible (Discover selected in [IndexedStack]).
///
/// [IndexedStack] keeps [DiscoverScreen] mounted, so [State.initState] does
/// not run again on tab return. Discover also re-reads prefs after candidates
/// finish loading and when [DiscoverGestureOnboardingStore.guidanceRevision]
/// bumps (debug replay), so overlay visibility is not tied only to this
/// visibility flip.
class DiscoverGestureOnboardingTabSync extends StatefulWidget {
  const DiscoverGestureOnboardingTabSync({
    super.key,
    required this.store,
    required this.onShowChanged,
    required this.child,
  });

  final DiscoverGestureOnboardingStore store;
  final ValueChanged<bool> onShowChanged;
  final Widget child;

  @override
  State<DiscoverGestureOnboardingTabSync> createState() =>
      _DiscoverGestureOnboardingTabSyncState();
}

class _DiscoverGestureOnboardingTabSyncState
    extends State<DiscoverGestureOnboardingTabSync> {
  bool? _wasVisible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = Visibility.of(context);
    if (_wasVisible == visible) return;
    _wasVisible = visible;
    if (visible) {
      _syncFromStore();
    }
  }

  Future<void> _syncFromStore() async {
    try {
      final seen = await widget.store.hasSeen();
      if (!mounted) return;
      widget.onShowChanged(!seen);
    } catch (e, st) {
      debugPrint('Discover gesture onboarding tab sync skipped: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
