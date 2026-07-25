import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
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
    final store = ref.watch(localStoreProvider);
    final email = ref.watch(authControllerProvider).user?.email ?? '—';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          const _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode_rounded),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(store.themeMode)),
            trailing: DropdownButton<String>(
              value: store.themeMode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('System')),
                DropdownMenuItem(value: 'dark', child: Text('Dark')),
                DropdownMenuItem(value: 'light', child: Text('Light')),
              ],
              onChanged: (value) async {
                if (value == null) return;
                await store.setThemeMode(value);
                setState(() {});
              },
            ),
          ),
          const _SectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_rounded),
            title: const Text('Quest reminders'),
            subtitle: const Text('Nudges when a streak is at risk'),
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
          ),
          const _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.mail_outline_rounded),
            title: const Text('Email'),
            subtitle: Text(email),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () {},
          ),
          const _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Version'),
            subtitle: Text('1.0.0 (1)'),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Sign out'),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }

  String _themeLabel(String mode) => switch (mode) {
        'dark' => 'Dark',
        'light' => 'Light',
        _ => 'System',
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
