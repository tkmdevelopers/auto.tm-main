import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:get_storage/get_storage.dart';

/// Report describing current cache / temp usage.
class CacheReport {
  final int videoCompressBytes;
  final int tempMediaBytes;
  final int compressedVideoBytes;
  final int orphanCompressedCount;
  final int draftCount;
  final int brandCacheEntries;
  final int modelCacheBrands;
  final int staleBrandModelEntries;
  final DateTime? lastActiveUploadTs;
  final List<String> warnings;

  CacheReport({
    required this.videoCompressBytes,
    required this.tempMediaBytes,
    required this.compressedVideoBytes,
    required this.orphanCompressedCount,
    required this.draftCount,
    required this.brandCacheEntries,
    required this.modelCacheBrands,
    required this.staleBrandModelEntries,
    required this.lastActiveUploadTs,
    required this.warnings,
  });

  String toPrettyString() {
    String fmt(int b) => _formatBytes(b);
    return [
      'VideoCompress: ' + fmt(videoCompressBytes),
      'Temp media: ' + fmt(tempMediaBytes),
      'Compressed current: ' + fmt(compressedVideoBytes),
      'Orphan compressed: $orphanCompressedCount',
      'Drafts: $draftCount',
      'Brand cache entries: $brandCacheEntries',
      'Model cache brands: $modelCacheBrands',
      'Stale brand/model entries: $staleBrandModelEntries',
      'Last active upload: ${lastActiveUploadTs?.toIso8601String() ?? '-'}',
      if (warnings.isNotEmpty) 'Warnings:\n  - ' + warnings.join('\n  - '),
    ].join('\n');
  }
}

/// Centralized cache cleaner & analyzer.
class AppCacheCleaner {
  static final AppCacheCleaner _singleton = AppCacheCleaner._();
  factory AppCacheCleaner() => _singleton;
  AppCacheCleaner._();

  final box = GetStorage();

  // Keys mirrored from controllers
  static const _persistKeyActiveUpload = 'ACTIVE_UPLOAD_V1';
  static const _brandCacheKey = 'BRAND_CACHE_V1';
  static const _modelCacheKey = 'MODEL_CACHE_V1';
  static const _draftKey = 'POST_DRAFTS_V1';

  // Thresholds
  static const int softVideoCompressLimit = 250 * 1024 * 1024; // 250MB
  static const int hardVideoCompressLimit = 400 * 1024 * 1024; // 400MB
  static const int maxDrafts = 25;
  static const Duration brandModelTtl = Duration(hours: 6);
  static const Duration activeUploadStale = Duration(minutes: 30);
  static const Duration orphanCompressedAge = Duration(hours: 6);

  Future<CacheReport> analyze({File? currentCompressed}) async {
    final warnings = <String>[];

    // VideoCompress cache size (best effort)
    int videoCompressBytes = 0;
    Directory? vcDir;
    try {
      vcDir = await _videoCompressCacheDir();
      if (vcDir != null) {
        videoCompressBytes = await _dirSize(vcDir, maxDepth: 4);
      }
    } catch (_) {}

    // Temp directory scan
    int tempMediaBytes = 0;
    int orphanCompressedCount = 0;
    try {
      final tmp = await getTemporaryDirectory();
      final now = DateTime.now();
      if (tmp.existsSync()) {
        for (final f in tmp.listSync(followLinks: false)) {
          if (f is File) {
            final name = f.path.split(Platform.pathSeparator).last;
            final isCandidate =
                name.startsWith('video_') ||
                name.startsWith('photo_') ||
                name.endsWith('.mp4');
            if (isCandidate) {
              final stat = await f.stat();
              tempMediaBytes += stat.size;
              if (now.difference(stat.modified) > orphanCompressedAge) {
                orphanCompressedCount++;
              }
            }
          }
        }
      }
    } catch (_) {}

    // Current compressed file size
    int compressedBytes = 0;
    if (currentCompressed != null) {
      try {
        if (currentCompressed.existsSync())
          compressedBytes = currentCompressed.lengthSync();
      } catch (_) {}
    }

    // Draft count
    int draftCount = 0;
    try {
      final raw = box.read(_draftKey);
      if (raw is List) draftCount = raw.length;
      if (draftCount > maxDrafts)
        warnings.add('Drafts exceed limit: $draftCount');
    } catch (_) {}

    // Brand/model cache stats
    int brandEntries = 0;
    int modelBrandCount = 0;
    int staleEntries = 0;
    final now = DateTime.now();
    try {
      final brandRaw = box.read(_brandCacheKey);
      if (brandRaw is Map) {
        brandEntries = (brandRaw['data'] is List)
            ? (brandRaw['data'] as List).length
            : 0;
        final tsStr = brandRaw['ts']?.toString();
        if (tsStr != null) {
          final ts = DateTime.tryParse(tsStr);
          if (ts != null && now.difference(ts) > brandModelTtl) staleEntries++;
        }
      }
      final modelRaw = box.read(_modelCacheKey);
      if (modelRaw is Map) {
        for (final v in modelRaw.values) {
          if (v is Map) {
            final tsStr = v['ts']?.toString();
            if (tsStr != null) {
              final ts = DateTime.tryParse(tsStr);
              if (ts != null && now.difference(ts) > brandModelTtl)
                staleEntries++;
            }
            modelBrandCount++;
          }
        }
      }
    } catch (_) {}

    // Active upload age
    DateTime? lastUploadTs;
    try {
      final raw = box.read(_persistKeyActiveUpload);
      if (raw is Map) {
        final tsStr = raw['timestamp']?.toString();
        lastUploadTs = DateTime.tryParse(tsStr ?? '');
        if (lastUploadTs != null &&
            now.difference(lastUploadTs) > activeUploadStale) {
          warnings.add('Active upload persistence is stale');
        }
      }
    } catch (_) {}

    // Threshold warnings
    if (videoCompressBytes > hardVideoCompressLimit) {
      warnings.add('VideoCompress cache exceeds HARD limit');
    } else if (videoCompressBytes > softVideoCompressLimit) {
      warnings.add('VideoCompress cache exceeds soft limit');
    }

    return CacheReport(
      videoCompressBytes: videoCompressBytes,
      tempMediaBytes: tempMediaBytes,
      compressedVideoBytes: compressedBytes,
      orphanCompressedCount: orphanCompressedCount,
      draftCount: draftCount,
      brandCacheEntries: brandEntries,
      modelCacheBrands: modelBrandCount,
      staleBrandModelEntries: staleEntries,
      lastActiveUploadTs: lastUploadTs,
      warnings: warnings,
    );
  }

  Future<void> clearLight() async {
    await _purgeExpiredBrandModel();
    await _pruneDrafts();
    await _purgeStaleActiveUpload();
  }

  Future<void> clearMedia({
    bool aggressive = false,
    File? currentCompressed,
  }) async {
    // Delete orphan temp media older than threshold
    try {
      final tmp = await getTemporaryDirectory();
      final now = DateTime.now();
      for (final entity in tmp.listSync(followLinks: false)) {
        if (entity is File) {
          final name = entity.path.split(Platform.pathSeparator).last;
          final stat = await entity.stat();
          final ageOk = now.difference(stat.modified) > orphanCompressedAge;
          if (ageOk &&
              (name.startsWith('video_') ||
                  name.startsWith('photo_') ||
                  name.endsWith('.mp4'))) {
            _safeDelete(entity);
          }
        }
      }
    } catch (_) {}

    // Remove currentCompressed if flagged not in use
    if (currentCompressed != null) {
      _safeDelete(currentCompressed);
    }

    // VideoCompress cache deletion based on size or aggressive
    try {
      final dir = await _videoCompressCacheDir();
      if (dir != null) {
        final size = await _dirSize(dir, maxDepth: 4);
        if (aggressive || size > softVideoCompressLimit) {
          await VideoCompress.deleteAllCache();
        }
      }
    } catch (_) {}
  }

  Future<void> clearAll({File? currentCompressed}) async {
    await clearMedia(aggressive: true, currentCompressed: currentCompressed);
    await clearLight();
    // Purge brand/model caches fully
    try {
      box.remove(_brandCacheKey);
    } catch (_) {}
    try {
      box.remove(_modelCacheKey);
    } catch (_) {}
  }

  Future<void> autoPruneIfNeeded() async {
    try {
      final report = await analyze();
      if (report.videoCompressBytes > hardVideoCompressLimit ||
          report.warnings.isNotEmpty) {
        await clearMedia(aggressive: true);
      } else if (report.videoCompressBytes > softVideoCompressLimit) {
        await clearMedia();
      }
      await clearLight();
    } catch (_) {}
  }

  Future<void> _purgeExpiredBrandModel() async {
    final now = DateTime.now();
    try {
      final brandRaw = box.read(_brandCacheKey);
      if (brandRaw is Map) {
        final tsStr = brandRaw['ts']?.toString();
        final ts = tsStr != null ? DateTime.tryParse(tsStr) : null;
        if (ts != null && now.difference(ts) > brandModelTtl) {
          box.remove(_brandCacheKey);
        }
      }
      final modelRaw = box.read(_modelCacheKey);
      if (modelRaw is Map) {
        final toRemove = <String>[];
        modelRaw.forEach((k, v) {
          if (v is Map) {
            final tsStr = v['ts']?.toString();
            final ts = tsStr != null ? DateTime.tryParse(tsStr) : null;
            if (ts != null && now.difference(ts) > brandModelTtl) {
              toRemove.add(k);
            }
          }
        });
        for (final k in toRemove) {
          modelRaw.remove(k);
        }
        if (toRemove.isNotEmpty) {
          box.write(_modelCacheKey, modelRaw);
        }
      }
    } catch (_) {}
  }

  Future<void> _pruneDrafts() async {
    try {
      final raw = box.read(_draftKey);
      if (raw is List && raw.length > maxDrafts) {
        // Assume each entry has a 'updatedAt' or 'savedAt' field; fallback to index order
        final enriched = <Map<String, dynamic>>[];
        for (final e in raw) {
          if (e is Map<String, dynamic>) {
            enriched.add(e);
          }
        }
        enriched.sort((a, b) {
          final aTs =
              DateTime.tryParse(
                a['updatedAt']?.toString() ?? a['savedAt']?.toString() ?? '',
              ) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bTs =
              DateTime.tryParse(
                b['updatedAt']?.toString() ?? b['savedAt']?.toString() ?? '',
              ) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bTs.compareTo(aTs); // newest first
        });
        final kept = enriched.take(maxDrafts).toList();
        box.write(_draftKey, kept);
      }
    } catch (_) {}
  }

  Future<void> _purgeStaleActiveUpload() async {
    try {
      final raw = box.read(_persistKeyActiveUpload);
      if (raw is Map) {
        final tsStr = raw['timestamp']?.toString();
        final ts = tsStr != null ? DateTime.tryParse(tsStr) : null;
        if (ts != null && DateTime.now().difference(ts) > activeUploadStale) {
          box.remove(_persistKeyActiveUpload);
        }
      }
    } catch (_) {}
  }

  Future<Directory?> _videoCompressCacheDir() async {
    try {
      // video_compress stores cache under temporary directory with "video_compress" subfolder (platform dependent)
      final tmp = await getTemporaryDirectory();
      final candidate = Directory(
        '${tmp.path}${Platform.pathSeparator}video_compress',
      );
      if (candidate.existsSync()) return candidate;
    } catch (_) {}
    return null;
  }

  Future<int> _dirSize(
    Directory dir, {
    int maxDepth = 5,
    int current = 0,
  }) async {
    if (current > maxDepth) return 0;
    int total = 0;
    try {
      final entities = dir.listSync(followLinks: false);
      for (final e in entities) {
        if (e is File) {
          try {
            total += e.lengthSync();
          } catch (_) {}
        } else if (e is Directory) {
          total += await _dirSize(e, maxDepth: maxDepth, current: current + 1);
        }
      }
    } catch (_) {}
    return total;
  }

  void _safeDelete(File f) {
    try {
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  double size = bytes.toDouble();
  int unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  return unitIndex <= 1
      ? '${size.toStringAsFixed(0)} ${units[unitIndex]}'
      : '${size.toStringAsFixed(1)} ${units[unitIndex]}';
}
