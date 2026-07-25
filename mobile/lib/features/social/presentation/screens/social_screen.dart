import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';

/// Social hub: entry points into Guild and PvP. Acts as the "Social" bottom-nav
/// branch root.
class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Social')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _HubCard(
            title: 'Your Guild',
            subtitle: 'Chat, shared missions, and the weekly leaderboard.',
            icon: Icons.groups_rounded,
            gradient: AppColors.heroGradient,
            onTap: () => context.pushNamed(AppRoute.guild.name),
          ),
          AppSpacing.vLg,
          _HubCard(
            title: 'PvP Arena',
            subtitle: 'Challenge friends to XP, study, or workout duels.',
            icon: Icons.sports_kabaddi_rounded,
            gradient: const LinearGradient(colors: [AppColors.tertiary, AppColors.accentDeep]),
            onTap: () => context.pushNamed(AppRoute.pvp.name),
          ),
          AppSpacing.vLg,
          GlassCard(
            blur: false,
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: AppColors.gold),
                AppSpacing.hMd,
                Expanded(child: Text('Global leaderboards', style: text.titleSmall)),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(gradient: gradient, borderRadius: AppRadius.rXl),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 40),
            AppSpacing.hLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleLarge?.copyWith(color: Colors.white)),
                  AppSpacing.gapXs,
                  Text(subtitle, style: text.bodySmall?.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
