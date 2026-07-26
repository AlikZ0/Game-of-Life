import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/l10n/app_localizations.dart';

import '../../../../core/config/di.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

/// Settings: theme, notifications, account, and about. Theme preference is
/// persisted to [LocalStore]; a full impl would drive an app-level ThemeMode
/// provider to rebuild [MaterialApp].
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(localStoreProvider);
    final localeCode = ref.watch(localeProvider)?.languageCode; // null → system
    final email = ref.watch(authControllerProvider).user?.email ?? '—';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          _SectionHeader(l10n.sectionAppearance),
          ListTile(
            leading: const Icon(Icons.dark_mode_rounded),
            title: Text(l10n.theme),
            subtitle: Text(_themeLabel(l10n, store.themeMode)),
            trailing: DropdownButton<String>(
              value: store.themeMode,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: 'system', child: Text(l10n.themeSystem)),
                DropdownMenuItem(value: 'dark', child: Text(l10n.themeDark)),
                DropdownMenuItem(value: 'light', child: Text(l10n.themeLight)),
              ],
              onChanged: (value) async {
                if (value == null) return;
                await store.setThemeMode(value);
                setState(() {});
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text(l10n.language),
            trailing: DropdownButton<String?>(
              value: localeCode,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.languageSystem)),
                const DropdownMenuItem(value: 'en', child: Text('English')),
                const DropdownMenuItem(value: 'ru', child: Text('Русский')),
                const DropdownMenuItem(value: 'uk', child: Text('Українська')),
                const DropdownMenuItem(value: 'pt', child: Text('Português')),
              ],
              onChanged: (value) =>
                  ref.read(localeProvider.notifier).setLocale(value),
            ),
          ),
          _SectionHeader(l10n.sectionNotifications),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_rounded),
            title: Text(l10n.questReminders),
            subtitle: Text(l10n.questRemindersSubtitle),
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
          ),
          _SectionHeader(l10n.sectionAccount),
          ListTile(
            leading: const Icon(Icons.mail_outline_rounded),
            title: Text(l10n.email),
            subtitle: Text(email),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyPolicy),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () {},
          ),
          _SectionHeader(l10n.sectionAbout),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(l10n.version),
            subtitle: const Text('1.0.0 (1)'),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: Text(l10n.logout),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }

  String _themeLabel(AppLocalizations l10n, String mode) => switch (mode) {
        'dark' => l10n.themeDark,
        'light' => l10n.themeLight,
        _ => l10n.themeSystem,
      };
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1),
      ),
    );
  }
}
