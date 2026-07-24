import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/business/country_catalog_sync.dart';
import 'core/business/feature_flags.dart';
import 'core/offline/local_db.dart';
import 'core/router/root_container.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ar');
  await LocalDb.init();
  CountryCatalogSync.loadCached();
  FeatureFlagsSync.loadCached();
  // Mounts the real widget tree on the same container appRouter's redirect
  // reads permissions from (see root_container.dart) — a plain
  // ProviderScope would create a second, unrelated container instead.
  runApp(UncontrolledProviderScope(container: rootContainer, child: const DukaniApp()));
  CountryCatalogSync.refreshFromCloud();
  FeatureFlagsSync.refreshFromCloud();
}
