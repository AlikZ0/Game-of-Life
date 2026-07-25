import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'primary_button.dart';

/// Centered spinner used while an [AsyncValue] is loading.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.accent),
          if (message != null) ...[
            AppSpacing.vLg,
            Text(message!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Friendly error state with a retry affordance.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_tethering_error_rounded, size: 48, color: AppColors.danger),
            AppSpacing.vLg,
            Text('Something went wrong', style: text.titleMedium, textAlign: TextAlign.center),
            AppSpacing.gapXs,
            Text(message, style: text.bodySmall, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              AppSpacing.vXl,
              PrimaryButton(label: 'Try again', icon: Icons.refresh_rounded, expand: false, onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}

/// Illustrative empty state for lists with no data yet.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.action,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 84,
              width: 84,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.accent),
            ),
            AppSpacing.vXl,
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              AppSpacing.gapXs,
              Text(subtitle!, style: text.bodySmall, textAlign: TextAlign.center),
            ],
            if (action != null) ...[AppSpacing.vXl, action!],
          ],
        ),
      ),
    );
  }
}
