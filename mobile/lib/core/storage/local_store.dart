import 'package:hive_flutter/hive_flutter.dart';

/// Hive-backed local cache for non-sensitive data: offline snapshots of the
/// character, cached quest lists, and UI preferences (theme mode, onboarding
/// seen). Tokens never go here — see [SecureStorage].
class LocalStore {
  LocalStore._(this._prefs, this._cache);

  final Box _prefs;
  final Box _cache;

  static const String _prefsBox = 'lq_prefs';
  static const String _cacheBox = 'lq_cache';

  static const String kOnboardingSeen = 'onboarding_seen';
  static const String kThemeMode = 'theme_mode'; // system | dark | light
  static const String kLocale = 'locale'; // null → follow system; else language code
  static const String kCachedCharacter = 'cached_character';

  /// Initialize Hive and open the app's boxes. Call once in bootstrap.
  static Future<LocalStore> init() async {
    await Hive.initFlutter();
    final prefs = await Hive.openBox(_prefsBox);
    final cache = await Hive.openBox(_cacheBox);
    return LocalStore._(prefs, cache);
  }

  // - Preferences -
  bool get onboardingSeen => _prefs.get(kOnboardingSeen, defaultValue: false) as bool;
  Future<void> setOnboardingSeen(bool value) => _prefs.put(kOnboardingSeen, value);

  String get themeMode => _prefs.get(kThemeMode, defaultValue: 'system') as String;
  Future<void> setThemeMode(String value) => _prefs.put(kThemeMode, value);

  /// Preferred locale language code (e.g. `en`, `ru`). `null` means follow the
  /// device locale.
  String? get localeCode => _prefs.get(kLocale) as String?;
  Future<void> setLocale(String? code) =>
      code == null ? _prefs.delete(kLocale) : _prefs.put(kLocale, code);

  // - Cache -
  Map<String, dynamic>? get cachedCharacter {
    final raw = _cache.get(kCachedCharacter);
    return raw == null ? null : Map<String, dynamic>.from(raw as Map);
  }

  Future<void> cacheCharacter(Map<String, dynamic> json) =>
      _cache.put(kCachedCharacter, json);

  Future<void> clearCache() => _cache.clear();
}
