import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';

/// Horizontal swipe shell around a Discover candidate card.
///
/// Right → [onLike], left → [onPass]. Same callbacks as the action bar.
/// Presentation only — no ranking / Firebase.
class QMatchDiscoverSwipeableCard extends StatefulWidget {
  const QMatchDiscoverSwipeableCard({
    super.key,
    required this.candidateId,
    required this.likeLabel,
    required this.passLabel,
    required this.onLike,
    required this.onPass,
    required this.child,
    this.enabled = true,
    this.showSwipeStamps = true,
    this.dragThreshold = defaultDragThreshold,
  });

  static const double defaultDragThreshold = 120;
  static const double overlayStartPx = 24;
  static const double maxRotationRadians = 0.14;
  static const Duration flyOffDuration = Duration(milliseconds: 220);

  final String candidateId;
  final String likeLabel;
  final String passLabel;
  final VoidCallback onLike;
  final VoidCallback onPass;
  final Widget child;
  final bool enabled;
  final bool showSwipeStamps;
  final double dragThreshold;

  @override
  State<QMatchDiscoverSwipeableCard> createState() =>
      _QMatchDiscoverSwipeableCardState();
}

class _QMatchDiscoverSwipeableCardState
    extends State<QMatchDiscoverSwipeableCard>
    with SingleTickerProviderStateMixin {
  Offset _offset = Offset.zero;
  bool _actionDispatched = false;
  late final AnimationController _controller;
  Animation<Offset>? _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(() {
        final anim = _offsetAnimation;
        if (anim == null) return;
        setState(() => _offset = anim.value);
      });
  }

  @override
  void didUpdateWidget(QMatchDiscoverSwipeableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candidateId != widget.candidateId) {
      _controller.stop();
      _offsetAnimation = null;
      _offset = Offset.zero;
      _actionDispatched = false;
      return;
    }
    if (!oldWidget.enabled && widget.enabled && _actionDispatched) {
      // Like/Pass failed or completed without advancing — restore the card.
      _actionDispatched = false;
      _snapBack();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _gesturesActive => widget.enabled && !_actionDispatched;

  double get _progress {
    final t = widget.dragThreshold <= 0
        ? 1.0
        : _offset.dx.abs() / widget.dragThreshold;
    return t.clamp(0.0, 1.0);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_gesturesActive) return;
    setState(
        () => _offset += Offset(details.delta.dx, details.delta.dy * 0.28));
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_gesturesActive) {
      if (!_actionDispatched) _snapBack();
      return;
    }
    final dx = _offset.dx;
    final pastThreshold = dx.abs() >= widget.dragThreshold;
    if (pastThreshold) {
      _commit(like: dx > 0);
    } else {
      _snapBack();
    }
  }

  void _onDragCancel() {
    if (!_actionDispatched) _snapBack();
  }

  void _commit({required bool like}) {
    if (_actionDispatched || !widget.enabled) return;
    _actionDispatched = true;
    if (like) {
      widget.onLike();
    } else {
      widget.onPass();
    }
    final width = MediaQuery.sizeOf(context).width;
    final end = Offset(
      (like ? 1.0 : -1.0) * (width + 80),
      _offset.dy,
    );
    _animateTo(end, duration: QMatchDiscoverSwipeableCard.flyOffDuration);
  }

  void _snapBack() {
    if (_offset == Offset.zero) return;
    _animateTo(Offset.zero, duration: const Duration(milliseconds: 240));
  }

  void _animateTo(
    Offset end, {
    required Duration duration,
  }) {
    _controller.stop();
    _controller.duration = duration;
    _offsetAnimation = Tween<Offset>(begin: _offset, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _offsetAnimation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rotation = (_offset.dx / 720).clamp(
      -QMatchDiscoverSwipeableCard.maxRotationRadians,
      QMatchDiscoverSwipeableCard.maxRotationRadians,
    );
    final likeOpacity = _offset.dx > QMatchDiscoverSwipeableCard.overlayStartPx
        ? _progress
        : 0.0;
    final passOpacity = _offset.dx < -QMatchDiscoverSwipeableCard.overlayStartPx
        ? _progress
        : 0.0;

    return GestureDetector(
      key: const Key('qmatch-discover-swipeable-card'),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _gesturesActive ? _onDragUpdate : null,
      onHorizontalDragEnd:
          _gesturesActive || _offset != Offset.zero ? _onDragEnd : null,
      onHorizontalDragCancel: _onDragCancel,
      child: Transform.translate(
        offset: _offset,
        child: Transform.rotate(
          angle: rotation,
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              if (widget.showSwipeStamps)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      children: [
                        Positioned(
                          top: AppSpacing.lg,
                          left: AppSpacing.md,
                          child: Opacity(
                            opacity: passOpacity,
                            child: _SwipeStamp(
                              key: const Key(
                                'qmatch-discover-swipe-pass-overlay',
                              ),
                              label: widget.passLabel,
                              color: AppColors.danger,
                              angle: -0.18,
                            ),
                          ),
                        ),
                        Positioned(
                          top: AppSpacing.lg,
                          right: AppSpacing.md,
                          child: Opacity(
                            opacity: likeOpacity,
                            child: _SwipeStamp(
                              key: const Key(
                                'qmatch-discover-swipe-like-overlay',
                              ),
                              label: widget.likeLabel,
                              color: AppColors.success,
                              angle: 0.18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeStamp extends StatelessWidget {
  const _SwipeStamp({
    super.key,
    required this.label,
    required this.color,
    required this.angle,
  });

  final String label;
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadii.buttonBorder,
          border: Border.all(color: color, width: 2.5),
          color: color.withValues(alpha: 0.16),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
      ),
    );
  }
}
