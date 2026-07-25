import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Outlined social sign-in button (Google / Apple) matching the design system.
class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.foreground,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = foreground ?? scheme.onSurface;
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: fg),
                  AppSpacing.hMd,
                  Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}
