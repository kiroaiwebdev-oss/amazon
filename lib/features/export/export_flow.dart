import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routing/app_router.dart';
import '../../app/theme/tokens.dart';
import '../../core/platform/platform_services.dart';
import '../../core/widgets/tc_scaffold.dart';
import '../../core/widgets/tc_widgets.dart';
import '../../data/models.dart';
import '../coloring/canvas_painter.dart';
import '../coloring/coloring_document.dart';

/// Screen 22 - Export Permission + the full export state machine
/// (explanation, permission required/denied/permanently denied, exporting,
/// success, cancelled, low storage, write failure).
///
/// The caller must have already passed the Adult Gate.
Future<void> runExportFlow(
  BuildContext context, {
  required Artwork artwork,
  required CatalogItem? item,
}) async {
  final state = context.read<AppState>();

  // 1) Explanation dialog - nothing is uploaded; PNG goes to the gallery.
  final proceed = await showTcModal<bool>(
    context,
    TcModalCard(
      icon: 'download',
      title: 'Save a PNG to the gallery?',
      body: 'TinyCanvas will save \u201c${artwork.displayName}\u201d as a PNG '
          'picture in this tablet\u2019s Pictures \u2192 TinyCanvas folder. '
          'Everything stays on the tablet - nothing is uploaded anywhere.',
      actions: [
        TcButton(
          label: 'Save PNG',
          icon: 'download',
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(true),
        ),
        TcButton(
          label: 'Cancel',
          kind: TcButtonKind.soft,
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
        ),
      ],
    ),
  );
  if (proceed != true || !context.mounted) return;

  // 2) Render the artwork document to PNG bytes.
  Uint8List? bytes;
  try {
    bytes = await _renderArtworkPng(state, artwork, item);
  } catch (_) {
    bytes = null;
  }
  if (!context.mounted) return;
  if (bytes == null) {
    await _showOutcome(
      context,
      icon: 'alert',
      title: 'We couldn\u2019t prepare the picture',
      body: 'The artwork file couldn\u2019t be read. Open the picture on the '
          'canvas once, then try saving again.',
    );
    return;
  }

  // 3) Exporting progress dialog while the platform write happens.
  final exportFuture = state.mediaExport.exportPng(
    fileName: sanitizeArtworkName(artwork.displayName).isEmpty
        ? 'TinyCanvas artwork'
        : sanitizeArtworkName(artwork.displayName),
    bytes: bytes,
  );
  showTcModal<void>(
    context,
    const TcModalCard(
      icon: 'download',
      title: 'Saving your masterpiece\u2026',
      body: 'Putting the PNG into the Pictures folder.',
      showProgress: true,
      actions: [],
    ),
    dismissible: false,
  );
  final result = await exportFuture;
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop(); // close progress

  // 4) Outcome dialogs.
  switch (result.outcome) {
    case ExportOutcome.success:
      await _showOutcome(
        context,
        icon: 'check',
        gold: true,
        title: 'Saved to the gallery!',
        body: 'The PNG is in Pictures \u2192 TinyCanvas'
            '${result.path != null ? ' (${result.path})' : ''}. '
            'You can share or print it from the Photos app.',
      );
    case ExportOutcome.permissionDenied:
      await _showOutcome(
        context,
        icon: 'shield',
        title: 'Permission needed',
        body: 'The tablet asked for permission to add pictures and it '
            'wasn\u2019t granted this time. Nothing was saved. Try again '
            'whenever you\u2019re ready.',
      );
    case ExportOutcome.permissionPermanentlyDenied:
      if (!context.mounted) return;
      final open = await showTcModal<bool>(
        context,
        TcModalCard(
          icon: 'shield',
          title: 'Permission is switched off',
          body: 'Saving pictures is currently blocked in the tablet '
              'settings. You can switch it back on in '
              'Apps & Notifications \u2192 TinyCanvas Adventures \u2192 '
              'Permissions \u2192 Allow Photos and media.',
          actions: [
            TcButton(
              label: 'Show me how',
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(true),
            ),
            TcButton(
              label: 'Not now',
              kind: TcButtonKind.soft,
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(false),
            ),
          ],
        ),
      );
      if (open == true && context.mounted) {
        Navigator.of(context).pushNamed(Routes.osSettingsGuidance);
      }
    case ExportOutcome.lowStorage:
      await _showOutcome(
        context,
        icon: 'alert',
        title: 'Not enough space',
        body: 'The tablet is low on storage, so the PNG couldn\u2019t be '
            'saved. Free up a little space and try again - your artwork is '
            'safe in My Art.',
      );
    case ExportOutcome.cancelled:
      // Quietly return; the caregiver cancelled.
      break;
    case ExportOutcome.writeFailed:
      await _showOutcome(
        context,
        icon: 'alert',
        title: 'Saving didn\u2019t work',
        body: 'Something interrupted the save and no file was written. Your '
            'artwork is still safe in My Art - please try again.',
      );
  }
}

Future<void> _showOutcome(
  BuildContext context, {
  required String icon,
  required String title,
  required String body,
  bool gold = false,
}) {
  return showTcModal<void>(
    context,
    TcModalCard(
      icon: icon,
      iconBg: gold ? TcColors.badgeGoldBg : null,
      title: title,
      body: body,
      actions: [
        TcButton(
          label: 'Okay',
          childFacing: true,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ],
    ),
  );
}

/// Renders the saved coloring document to a 1680x1424 PNG (paper aspect
/// 1.18) using the same CanvasPainter that draws the live canvas.
Future<Uint8List?> _renderArtworkPng(
  AppState state,
  Artwork artwork,
  CatalogItem? item,
) async {
  final raw = await state.documentStore.load(artwork.documentPath);
  final document = raw == null
      ? ColoringDocument.empty(artwork.catalogItemId)
      : ColoringDocument.fromJsonString(raw);

  const width = 1680.0;
  const height = width / ColoringDocument.paperAspect;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  CanvasPainter(
    ops: document.effectiveOps,
    liveOp: null,
    lineArtSeed: item?.assetSeed ?? 1,
    repaint: const AlwaysStoppedAnimation(0),
  ).paint(canvas, const Size(width, height));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width.toInt(), height.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data?.buffer.asUint8List();
}
