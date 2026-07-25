import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_value_views.dart';
import '../providers/bosses_providers.dart';
import '../widgets/boss_card.dart';

/// Bosses tab: a two-column gallery of active + defeated bosses.
class BossesScreen extends ConsumerWidget {
  const BossesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bosses = ref.watch(bossesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bosses')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.tertiary,
        onPressed: () {},
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Summon boss', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(bossesProvider),
        child: bosses.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(bossesProvider)),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyView(
                title: 'No bosses yet',
                subtitle: 'Turn a big goal into a boss and defeat it with daily quests.',
                icon: Icons.local_fire_department_rounded,
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.82,
              ),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final boss = list[i];
                return BossCard(
                  boss: boss,
                  onTap: () => context.pushNamed(
                    AppRoute.bossDetail.name,
                    pathParameters: {'bossId': boss.id},
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
