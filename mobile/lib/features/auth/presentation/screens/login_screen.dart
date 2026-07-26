import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:life_quest/l10n/app_localizations.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_controller.dart';
import '../widgets/social_auth_button.dart';

/// Flagship sign-in screen: hero brand mark, email/password, Google + Apple,
/// and a route to registration. Dark-first with a subtle aurora backdrop.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .loginWithEmail(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(authControllerProvider);

    // Surface auth errors as a snackbar.
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.error!.message)));
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          const _AuroraBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.huge),
                  const _BrandMark(),
                  AppSpacing.vXxl,
                  Text(l10n.welcomeBack, style: text.displayMedium),
                  AppSpacing.gapXs,
                  Text(
                    l10n.questsWaitingSubtitle,
                    style: text.bodyMedium?.copyWith(color: AppColors.textSecondaryDark),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: l10n.email,
                            prefixIcon: const Icon(Icons.mail_outline_rounded),
                          ),
                          validator: _validateEmail,
                        ),
                        AppSpacing.vLg,
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.length < 8) ? l10n.passwordTooShort : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(l10n.forgotPassword),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.vMd,
                  PrimaryButton(
                    label: l10n.signIn,
                    icon: Icons.bolt_rounded,
                    isLoading: state.isSubmitting,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  const _OrDivider(),
                  const SizedBox(height: AppSpacing.xxl),
                  SocialAuthButton(
                    label: l10n.signInWithGoogle,
                    icon: Icons.g_mobiledata_rounded,
                    onPressed: ref.read(authControllerProvider.notifier).loginWithGoogle,
                  ),
                  AppSpacing.vMd,
                  SocialAuthButton(
                    label: l10n.signInWithApple,
                    icon: Icons.apple_rounded,
                    onPressed: ref.read(authControllerProvider.notifier).loginWithApple,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.newToLifeQuest, style: text.bodyMedium),
                      TextButton(
                        onPressed: () => context.pushNamed(AppRoute.register.name),
                        child: Text(l10n.createHero),
                      ),
                    ],
                  ),
                  AppSpacing.vXl,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? v) {
    final l10n = AppLocalizations.of(context);
    if (v == null || v.isEmpty) return l10n.emailRequired;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : l10n.emailInvalid;
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: AppRadius.rLg,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.shield_moon_rounded, color: Colors.white, size: 30),
        ),
        AppSpacing.hMd,
        Text(AppLocalizations.of(context).appName,
            style: Theme.of(context).textTheme.headlineMedium),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Row(
      children: [
        Expanded(child: Divider(color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(AppLocalizations.of(context).orDivider,
              style: Theme.of(context).textTheme.labelSmall),
        ),
        Expanded(child: Divider(color: color)),
      ],
    );
  }
}

/// Soft radial "aurora" glows for the auth backdrop.
class _AuroraBackdrop extends StatelessWidget {
  const _AuroraBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _glow(AppColors.accent.withValues(alpha: 0.35), 320),
            ),
            Positioned(
              bottom: -140,
              left: -100,
              child: _glow(AppColors.secondary.withValues(alpha: 0.22), 360),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glow(Color color, double size) => Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      );
}
