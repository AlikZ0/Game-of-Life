import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_value_views.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../character/presentation/providers/character_providers.dart';
import '../../../character/presentation/widgets/character_card.dart';

/// Profile tab: the character hero card plus a menu into achievements,
/// inventory, stats, settings, and the premium paywall.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final character = ref.watch(myCharacterProvider);

    final menu = <(IconData, String, AppRoute)>[
      (Icons.emoji_events_rounded, 'Achievements', AppRoute.achievements),
      (Icons.backpack_rounded, 'Inventory', AppRoute.inventory),
      (Icons.insights_rounded, 'Statistics', AppRoute.stats),
      (Icons.local_fire_department_rounded, 'Streak', AppRoute.streaks),
      (Icons.workspace_premium_rounded, 'Battle Pass', AppRoute.battlePass),
      (Icons.settings_rounded, 'Settings', AppRoute.settings),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.pushNamed(AppRoute.settings.name),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          character.when(
            data: (c) => CharacterCard(character: c),
            loading: () => const SizedBox(height: 220, child: LoadingView()),
            error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(myCharacterProvider)),
          ),
          AppSpacing.vXl,
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: AppRadius.rLg),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Colors.black),
                AppSpacing.hMd,
                Expanded(
                  child: Text('Go Premium — unlock the full journey',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.black)),
                ),
                TextButton(
                  onPressed: () => context.pushNamed(AppRoute.paywall.name),
                  child: const Text('Upgrade', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          AppSpacing.vXl,
          for (final item in menu)
            ListTile(
              leading: Icon(item.$1, color: AppColors.accent),
              title: Text(item.$2),
              trailing: const Icon(Icons.chevron_right_rounded),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
              onTap: () => context.pushNamed(item.$3.name),
            ),
          AppSpacing.vLg,
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            label: const Text('Sign out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
