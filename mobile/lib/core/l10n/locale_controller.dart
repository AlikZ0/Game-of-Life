import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/di.dart';
import '../storage/local_store.dart';

/// Holds the user's preferred [Locale], persisted to [LocalStore].
///
/// A `null` state means "follow the system locale" — [MaterialApp.locale] is
/// left null so Flutter resolves against the device settings.
class LocaleController extends StateNotifier<Locale?> {
  LocaleController(this._store) : super(_decode(_store.localeCode));

  final LocalStore _store;

  static Locale? _decode(String? code) => code == null ? null : Locale(code);

  /// Update the preferred locale. Pass `null` to follow the system locale.
  Future<void> setLocale(String? languageCode) async {
    await _store.setLocale(languageCode);
    state = _decode(languageCode);
  }
}

/// App-wide locale preference. `null` = follow the system locale.
final localeProvider = StateNotifierProvider<LocaleController, Locale?>(
  (ref) => LocaleController(ref.watch(localStoreProvider)),
);
