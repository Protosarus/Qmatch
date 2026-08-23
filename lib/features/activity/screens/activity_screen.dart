import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../models/activity_event_model.dart';
import '../services/activity_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({
    super.key,
    this.activityStream,
  });

  @visibleForTesting
  final Stream<List<ActivityEventModel>>? activityStream;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  ActivityService? _activityService;

  int _streamEpoch = 0;

  Stream<List<ActivityEventModel>> _activityStream() {
    final injected = widget.activityStream;
    if (injected != null) return injected;

    final service = _activityService ??= ActivityService();
    return service.getMyActivityStream();
  }

  void _retry() {
    setState(() => _streamEpoch++);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      key: const Key('qmatch-activity-screen'),
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                l10n.activityTitle,
                key: const Key('activity-screen-title'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ActivityEventModel>>(
                key: ValueKey('activity-stream-$_streamEpoch'),
                stream: _activityStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData &&
                      !snapshot.hasError) {
                    return _ActivityCenteredState(
                      key: const Key('activity-loading-state'),
                      icon: Icons.bolt_rounded,
                      title: l10n.activityLoading,
                    );
                  }

                  if (snapshot.hasError) {
                    debugPrint('Activity stream error: ${snapshot.error}');
                    return _ActivityCenteredState(
                      key: const Key('activity-error-state'),
                      icon: Icons.cloud_off_rounded,
                      title: l10n.activityLoadErrorTitle,
                      subtitle: l10n.activityLoadErrorSubtitle,
                      actionLabel: l10n.activityRetry,
                      onAction: _retry,
                    );
                  }

                  final events = snapshot.data ?? const <ActivityEventModel>[];

                  if (events.isEmpty) {
                    return _ActivityCenteredState(
                      key: const Key('activity-empty-state'),
                      icon: Icons.auto_awesome_rounded,
                      title: l10n.activityEmptyTitle,
                      subtitle: l10n.activityEmptySubtitle,
                      accentIcon: true,
                    );
                  }

                  return ListView.separated(
                    key: const Key('qmatch-activity-list'),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    itemCount: events.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      return _ActivityEventCard(
                        event: events[index],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityEventCard extends StatelessWidget {
  const _ActivityEventCard({
    required this.event,
  });

  final ActivityEventModel event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actorName = event.actorName?.trim().isNotEmpty == true
        ? event.actorName!.trim()
        : l10n.activityFallbackName;

    final description = _description(
      l10n,
      actorName,
      event.type,
    );

    final photoUrl = event.actorPhotoUrl?.trim();
    final addedPhotoUrl = event.photoUrl?.trim();

    return Container(
      key: ValueKey('activity-event-${event.id}'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderSubtle,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.surfaceElevated,
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? Icon(
                        _iconForType(event.type),
                        color: AppColors.textGold,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    if (event.createdAt != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        _formatTimestamp(
                          context,
                          event.createdAt!.toDate(),
                        ),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                _iconForType(event.type),
                color: AppColors.textGold,
                size: 20,
              ),
            ],
          ),
          if (event.type == ActivityEventType.photoAdded &&
              addedPhotoUrl != null &&
              addedPhotoUrl.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  addedPhotoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: AppColors.surfaceElevated,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textMuted,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _description(
    AppLocalizations l10n,
    String actorName,
    ActivityEventType type,
  ) {
    switch (type) {
      case ActivityEventType.photoAdded:
        return l10n.activityPhotoAdded(actorName);
      case ActivityEventType.bioUpdated:
        return l10n.activityBioUpdated(actorName);
      case ActivityEventType.workEducationUpdated:
        return l10n.activityWorkEducationUpdated(actorName);
      case ActivityEventType.matchCreated:
        return l10n.activityMatchCreated(actorName);
      case ActivityEventType.superResonanceReceived:
        return l10n.activitySuperResonanceReceived(actorName);
      case ActivityEventType.anthemUpdated:
        return l10n.activityAnthemUpdated(actorName);
      case ActivityEventType.unknown:
        return actorName;
    }
  }

  IconData _iconForType(ActivityEventType type) {
    switch (type) {
      case ActivityEventType.photoAdded:
        return Icons.add_a_photo_rounded;
      case ActivityEventType.bioUpdated:
        return Icons.edit_note_rounded;
      case ActivityEventType.workEducationUpdated:
        return Icons.work_outline_rounded;
      case ActivityEventType.matchCreated:
        return Icons.favorite_rounded;
      case ActivityEventType.superResonanceReceived:
        return Icons.bolt_rounded;
      case ActivityEventType.anthemUpdated:
        return Icons.music_note_rounded;
      case ActivityEventType.unknown:
        return Icons.auto_awesome_rounded;
    }
  }

  String _formatTimestamp(
    BuildContext context,
    DateTime date,
  ) {
    final localDate = date.toLocal();
    final material = MaterialLocalizations.of(context);

    return '${material.formatShortDate(localDate)} · '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(localDate))}';
  }
}

class _ActivityCenteredState extends StatelessWidget {
  const _ActivityCenteredState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accentIcon = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Empty-state treatment: violet/blue accent instead of gold.
  final bool accentIcon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (accentIcon)
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.resonanceViolet.withValues(alpha: 0.42),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.resonanceViolet,
                        AppColors.electricBlue,
                      ],
                    ).createShader(bounds);
                  },
                  child: Icon(
                    icon,
                    color: AppColors.textPrimary,
                    size: 34,
                  ),
                ),
              )
            else
              Icon(
                icon,
                color: AppColors.textGold,
                size: 34,
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
