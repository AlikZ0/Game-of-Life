import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/di.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';

/// Three-panel intro carousel. Persists a "seen" flag so it only shows once.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = <_OnboardingPage>[
    _OnboardingPage(
      icon: Icons.explore_rounded,
      color: AppColors.accent,
      title: 'Turn habits into quests',
      body: 'Every workout, study session, and good decision earns real XP and gold.',
    ),
    _OnboardingPage(
      icon: Icons.local_fire_department_rounded,
      color: AppColors.tertiary,
      title: 'Defeat your Bosses',
      body: 'Big goals become HP bars. Chip away with daily quests until they fall.',
    ),
    _OnboardingPage(
      icon: Icons.groups_rounded,
      color: AppColors.secondary,
      title: 'Level up together',
      body: 'Join guilds, climb leaderboards, and challenge friends to PvP.',
    ),
  ];

  Future<void> _finish() async {
    await ref.read(localStoreProvider).setOnboardingSeen(true);
    if (mounted) context.goNamed(AppRoute.login.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _finish, child: const Text('Skip')),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            _Dots(count: _pages.length, index: _index),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: PrimaryButton(
                label: isLast ? 'Begin your quest' : 'Next',
                icon: isLast ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded,
                onPressed: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 160,
            width: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
              ),
            ),
            child: Icon(icon, size: 84, color: color),
          ),
          const SizedBox(height: AppSpacing.huge),
          Text(title, style: text.displayMedium, textAlign: TextAlign.center),
          AppSpacing.vLg,
          Text(
            body,
            style: text.bodyLarge?.copyWith(color: AppColors.textSecondaryDark),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: i == index ? 24 : 8,
            decoration: BoxDecoration(
              color: i == index ? AppColors.accent : AppColors.darkBorder,
              borderRadius: AppRadius.rPill,
            ),
          ),
      ],
    );
  }
}
