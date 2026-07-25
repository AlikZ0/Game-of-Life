import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/di.dart';
import 'core/storage/local_store.dart';

/// App entry point. Performs async bootstrap (Hive local store) before mounting
/// the widget tree, then injects the initialized [LocalStore] into the provider
/// graph via a [ProviderScope] override.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  final localStore = await LocalStore.init();

  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
      ],
      child: const LifeQuestApp(),
    ),
  );
}
