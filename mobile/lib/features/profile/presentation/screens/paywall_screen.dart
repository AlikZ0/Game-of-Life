import 'package:flutter/material.dart';
import 'package:life_quest/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';

/// Premium paywall: value props, plan selection, and a CTA. A production build
/// wires the CTA to Stripe / StoreKit / Play Billing via `/billing/checkout`.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _plan = 1; // 0 monthly, 1 yearly

  static const _perks = [
    ('Unlimited bosses & quests', Icons.all_inclusive_rounded),
    ('Premium battle pass track', Icons.workspace_premium_rounded),
    ('Advanced stats & AI coach', Icons.insights_rounded),
    ('Exclusive cosmetics & titles', Icons.palette_rounded),
    ('Streak freezes each month', Icons.ac_unit_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 320,
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 64),
                      AppSpacing.vMd,
                      Text(l10n.premiumTitle,
                          style: text.displaySmall?.copyWith(color: Colors.white),
                          textAlign: TextAlign.center),
                      AppSpacing.gapXs,
                      Text(l10n.premiumSubtitle,
                          style: text.bodyMedium?.copyWith(color: Colors.white70),
                          textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.huge),
                      for (final perk in _perks) _Perk(label: perk.$1, icon: perk.$2),
                      AppSpacing.vXl,
                      _PlanTile(
                        title: 'Yearly',
                        price: r'$59.99 / yr',
                        badge: 'Save 40%',
                        selected: _plan == 1,
                        onTap: () => setState(() => _plan = 1),
                      ),
                      AppSpacing.vMd,
                      _PlanTile(
                        title: 'Monthly',
                        price: r'$8.99 / mo',
                        selected: _plan == 0,
                        onTap: () => setState(() => _plan = 0),
                      ),
                      AppSpacing.vXl,
                      PrimaryButton(
                        label: 'Start 7-day free trial',
                        icon: Icons.auto_awesome_rounded,
                        gradient: AppColors.goldGradient,
                        onPressed: () {},
                      ),
                      AppSpacing.vMd,
                      Center(
                        child: Text(l10n.cancelAnytime, style: text.labelSmall),
                      ),
                      AppSpacing.vXl,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.16), borderRadius: AppRadius.rMd),
            child: const Icon(Icons.check_rounded, color: AppColors.accent, size: 20),
          ),
          AppSpacing.hMd,
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.price,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppRadius.rLg,
          border: Border.all(color: selected ? AppColors.accent : scheme.outline, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: selected ? AppColors.accent : scheme.outline),
            AppSpacing.hMd,
            Text(title, style: text.titleMedium),
            if (badge != null) ...[
              AppSpacing.hSm,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.success, borderRadius: AppRadius.rPill),
                child: Text(badge!, style: text.labelSmall?.copyWith(color: Colors.white)),
              ),
            ],
            const Spacer(),
            Text(price, style: text.titleSmall),
          ],
        ),
      ),
    );
  }
}
