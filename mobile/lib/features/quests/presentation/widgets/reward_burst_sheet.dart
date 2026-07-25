import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/quest_reward.dart';

/// Celebratory bottom sheet shown after completing a quest. This is the "juice"
/// hook — a scale/fade burst summarizing XP, gold, skill, boss damage, streak,
/// and any level-up. A real build would layer a confetti/particle overlay here.
class RewardBurstSheet extends StatefulWidget {
  const RewardBurstSheet({super.key, required this.reward});
  final QuestReward reward;

  static Future<void> show(BuildContext context, QuestReward reward) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => RewardBurstSheet(reward: reward),
      );

  @override
  State<RewardBurstSheet> createState() => _RewardBurstSheetState();
}

class _RewardBurstSheetState extends State<RewardBurstSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = widget.reward;
    final scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: scale,
            child: Container(
              height: 96,
              width: 96,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                r.bossDefeated ? Icons.emoji_events_rounded : Icons.check_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
          AppSpacing.vXl,
          Text(
            r.leveledUp ? 'Level up! You reached Lvl ${r.newLevel}' : 'Quest complete!',
            style: text.headlineMedium,
            textAlign: TextAlign.center,
          ),
          AppSpacing.vLg,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              _RewardChip(icon: Icons.bolt_rounded, label: Formatters.xp(r.xpAwarded), color: AppColors.xp),
              _RewardChip(icon: Icons.paid_rounded, label: '+${Formatters.count(r.goldAwarded)} gold', color: AppColors.gold),
              if (r.skillXp > 0)
                _RewardChip(icon: Icons.auto_graph_rounded, label: '+${r.skillXp} ${r.skillKey ?? 'skill'}', color: AppColors.secondary),
              if (r.bossDamage > 0)
                _RewardChip(icon: Icons.local_fire_department_rounded, label: '${r.bossDamage} dmg', color: AppColors.tertiary),
              if (r.streakCount > 0)
                _RewardChip(icon: Icons.whatshot_rounded, label: '${r.streakCount}-day streak', color: AppColors.warning),
            ],
          ),
          if (r.bossDefeated) ...[
            AppSpacing.vLg,
            Text('Boss defeated! 🏆', style: text.titleMedium?.copyWith(color: AppColors.gold)),
          ],
          AppSpacing.vXxl,
          PrimaryButton(
            label: 'Claim rewards',
            icon: Icons.auto_awesome_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppRadius.rPill,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          AppSpacing.hSm,
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}
