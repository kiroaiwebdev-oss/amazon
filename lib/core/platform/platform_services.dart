import 'dart:io';

import 'package:flutter/services.dart';

/// Platform integrations: connectivity probing and MediaStore PNG export.
/// Everything has an in-app mock so the whole app runs and tests without
/// real platform channels.

// ---------------------------------------------------------------------------
// Connectivity
// ---------------------------------------------------------------------------

abstract class ConnectivityService {
  /// True when the device currently appears to have internet access.
  Future<bool> hasNetwork();
}

/// Real probe: a short DNS lookup. Used only when the caregiver initiates a
/// network action (paywall, restore); coloring never needs it.
class IoConnectivityService implements ConnectivityService {
  @override
  Future<bool> hasNetwork() async {
    try {
      final result = await InternetAddress.lookup('www.amazon.com')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

class MockConnectivityService implements ConnectivityService {
  MockConnectivityService({this.online = true});

  bool online;

  @override
  Future<bool> hasNetwork() async => online;
}

// ---------------------------------------------------------------------------
// MediaStore export + storage
// ---------------------------------------------------------------------------

enum ExportOutcome {
  success,
  permissionDenied,
  permissionPermanentlyDenied,
  lowStorage,
  cancelled,
  writeFailed,
}

class ExportResult {
  const ExportResult(this.outcome, [this.path]);

  final ExportOutcome outcome;

  /// User-facing gallery location on success.
  final String? path;
}

class StorageSummary {
  const StorageSummary({
    required this.appBytes,
    required this.artworkBytes,
    required this.freeBytes,
  });

  final int appBytes;
  final int artworkBytes;
  final int freeBytes;
}

abstract class MediaExportService {
  /// Writes a PNG into the device gallery (Pictures/TinyCanvas) via
  /// MediaStore. Permission is requested by the platform side only when
  /// this is called - never at app start.
  Future<ExportResult> exportPng({
    required String fileName,
    required Uint8List bytes,
  });

  Future<StorageSummary> storageSummary({required Directory documentsDir});

  /// Deletes regenerable thumbnails; returns bytes freed.
  Future<int> clearThumbnailCache({required Directory documentsDir});
}

/// Production implementation bridging to the Android embedding over the
/// `tinycanvas/media_export` channel (MediaStore insert, scoped storage,
/// no broad storage permissions).
class ChannelMediaExportService implements MediaExportService {
  ChannelMediaExportService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('tinycanvas/media_export');

  final MethodChannel _channel;

  @override
  Future<ExportResult> exportPng({
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'exportPng',
        {'fileName': fileName, 'bytes': bytes},
      );
      final status = res?['status'] as String?;
      return switch (status) {
        'success' =>
          ExportResult(ExportOutcome.success, res?['path'] as String?),
        'permission_denied' =>
          const ExportResult(ExportOutcome.permissionDenied),
        'permission_permanently_denied' =>
          const ExportResult(ExportOutcome.permissionPermanentlyDenied),
        'low_storage' => const ExportResult(ExportOutcome.lowStorage),
        'cancelled' => const ExportResult(ExportOutcome.cancelled),
        _ => const ExportResult(ExportOutcome.writeFailed),
      };
    } on PlatformException {
      return const ExportResult(ExportOutcome.writeFailed);
    } on MissingPluginException {
      return const ExportResult(ExportOutcome.writeFailed);
    }
  }

  @override
  Future<StorageSummary> storageSummary(
      {required Directory documentsDir}) async {
    final appBytes = await _dirSize(documentsDir);
    final artworkBytes =
        await _dirSize(Directory('${documentsDir.path}/artworks'));
    var freeBytes = 0;
    try {
      freeBytes = await _channel.invokeMethod<int>('getFreeBytes') ?? 0;
    } on PlatformException {
      freeBytes = 0;
    } on MissingPluginException {
      freeBytes = 0;
    }
    return StorageSummary(
      appBytes: appBytes,
      artworkBytes: artworkBytes,
      freeBytes: freeBytes,
    );
  }

  @override
  Future<int> clearThumbnailCache({required Directory documentsDir}) =>
      _clearThumbnails(documentsDir);
}

/// In-app mock: keeps exports in memory, deterministic outcomes for every
/// approved export state, real directory math for the storage summary.
class MockMediaExportService implements MediaExportService {
  MockMediaExportService({
    this.scriptedOutcome = ExportOutcome.success,
    this.mockFreeBytes = 6 * 1024 * 1024 * 1024,
  });

  ExportOutcome scriptedOutcome;
  int mockFreeBytes;
  final List<String> exportedFiles = [];

  @override
  Future<ExportResult> exportPng({
    required String fileName,
    required Uint8List bytes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (scriptedOutcome != ExportOutcome.success) {
      return ExportResult(scriptedOutcome);
    }
    final path = 'Pictures/TinyCanvas/$fileName.png';
    exportedFiles.add(path);
    return ExportResult(ExportOutcome.success, path);
  }

  @override
  Future<StorageSummary> storageSummary(
      {required Directory documentsDir}) async {
    final appBytes = await _dirSize(documentsDir);
    final artworkBytes =
        await _dirSize(Directory('${documentsDir.path}/artworks'));
    return StorageSummary(
      appBytes: appBytes,
      artworkBytes: artworkBytes,
      freeBytes: mockFreeBytes,
    );
  }

  @override
  Future<int> clearThumbnailCache({required Directory documentsDir}) =>
      _clearThumbnails(documentsDir);
}

Future<int> _dirSize(Directory dir) async {
  if (!await dir.exists()) return 0;
  var total = 0;
  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      try {
        total += await entity.length();
      } catch (_) {
        // File vanished mid-scan; skip.
      }
    }
  }
  return total;
}

Future<int> _clearThumbnails(Directory documentsDir) async {
  final dir = Directory('${documentsDir.path}/thumbnails');
  final freed = await _dirSize(dir);
  if (await dir.exists()) {
    try {
      await dir.delete(recursive: true);
    } catch (_) {
      return 0;
    }
  }
  return freed;
}

/// Friendly byte formatting for the Parent Zone storage summary.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = -1;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[unit]}';
}
