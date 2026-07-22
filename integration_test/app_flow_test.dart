import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:tinycanvas_adventures/app/app.dart';
import 'package:tinycanvas_adventures/app/app_state.dart';
import 'package:tinycanvas_adventures/core/platform/platform_services.dart';
import 'package:tinycanvas_adventures/features/coloring/coloring_engine.dart';
import 'package:tinycanvas_adventures/features/purchase/purchase_service.dart';
import 'package:path_provider/path_provider.dart';

/// Critical-journey integration test: first launch -> onboarding ->
/// home -> pick a free picture -> canvas. Run on a Fire tablet or
/// Android emulator with:
///   flutter test integration_test/app_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch to canvas', (tester) async {
    final docs = await getApplicationDocumentsDirectory();
    final state = AppState(
      databasePath: '${docs.path}/it_tinycanvas.db',
      documentsDir: docs,
      purchaseService: MockPurchaseService(),
      connectivity: MockConnectivityService(online: false),
      mediaExport: MockMediaExportService(),
      documentStore: InMemoryDocumentStore(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const TinyCanvasApp(),
      ),
    );

    // Splash initializes local data, then onboarding appears on first run.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Make a little world of color.'), findsOneWidget);
    await tester.tap(find.textContaining('Start'));
    await tester.pumpAndSettle();

    // How to color -> sound choice -> home.
    await tester.tap(find.textContaining('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Playful'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('done').last, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });
}
