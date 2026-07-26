import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/di.dart';
import 'core/l10n/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/storage/local_store.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

/// Root widget. Wires the theme + router. Theme mode is read from [LocalStore]
/// so the user's preference (system/dark/light) persists between launches.
class LifeQuestApp extends ConsumerWidget {
  const LifeQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = _resolveThemeMode(ref.watch(localStoreProvider));
    final locale = ref.watch(localeProvider); // null → follow system

    return MaterialApp.router(
      title: 'Life Quest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  ThemeMode _resolveThemeMode(LocalStore store) => switch (store.themeMode) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.dark, // dark-first default
      };
}
