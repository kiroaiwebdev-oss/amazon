import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/app_state.dart';
import 'core/platform/platform_services.dart';
import 'features/purchase/purchase_service.dart';

/// Selects the purchase backend at build time:
///   flutter build apk --dart-define=TINYCANVAS_PURCHASE_BACKEND=amazon
/// Defaults to the mock service so every purchase state can be exercised
/// without the Amazon Appstore.
const _purchaseBackend = String.fromEnvironment(
  'TINYCANVAS_PURCHASE_BACKEND',
  defaultValue: 'mock',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final documentsDir = await getApplicationDocumentsDirectory();
  await Directory('${documentsDir.path}/artworks').create(recursive: true);

  final purchaseService = _purchaseBackend == 'amazon'
      ? AmazonIapPurchaseService()
      : MockPurchaseService();

  final mediaExport = _purchaseBackend == 'amazon'
      ? ChannelMediaExportService()
      : MockMediaExportService() as MediaExportService;

  final appState = AppState(
    databasePath: '${documentsDir.path}/tinycanvas.db',
    documentsDir: documentsDir,
    purchaseService: purchaseService,
    connectivity: IoConnectivityService(),
    mediaExport: mediaExport,
  );

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const TinyCanvasApp(),
    ),
  );
}
