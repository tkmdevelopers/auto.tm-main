import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../model/draft_model.dart';
import 'package:auto_tm/utils/hashing.dart';

/// Service responsible solely for draft persistence, loading, pruning and CRUD.
/// Controller now becomes a thin intent emitter and state holder.
class DraftService extends GetxService {
  static const String _storageKey = 'POST_DRAFTS_V1';
  static const int maxDrafts = 10;
  final GetStorage _box;

  DraftService({GetStorage? box}) : _box = box ?? GetStorage();

  final RxList<PostDraft> drafts = <PostDraft>[].obs;
  final RxBool isLoading = false.obs;
  final Rxn<DateTime> lastSavedAt = Rxn<DateTime>();

  Future<DraftService> init() async {
    await loadDrafts();
    return this;
  }

  /// Load all drafts from storage (sorted by updatedAt desc)
  Future<void> loadDrafts() async {
    isLoading.value = true;
    try {
      final raw = _box.read(_storageKey);
      if (raw is List) {
        final loaded = raw
            .whereType<Map>()
            .map((m) => PostDraft.fromMap(Map<String, dynamic>.from(m)))
            .toList();
        loaded.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        drafts.assignAll(loaded);
      }
    } catch (e) {
      Get.log('[DraftService] loadDrafts error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Returns the most recently updated draft or null if none
  PostDraft? loadLatestDraft() {
    if (drafts.isEmpty) return null;
    return drafts.first;
  }

  /// Persist all drafts to storage
  void _persist() {
    try {
      _box.write(_storageKey, drafts.map((d) => d.toMap()).toList());
    } catch (e) {
      Get.log('[DraftService] persist error: $e');
    }
  }

  /// Compute a signature hash for a map snapshot (delegates to hashing util)
  String computeSignature(Map<String, dynamic> snapshot) =>
      HashingUtils.computeSignature(snapshot);

  /// Upsert (create or update) a draft, enforcing capacity & pruning rules
  void upsert(PostDraft draft) {
    final idx = drafts.indexWhere((d) => d.id == draft.id);
    if (idx >= 0) {
      drafts[idx] = draft;
    } else {
      drafts.add(draft);
    }
    if (drafts.length > maxDrafts) {
      drafts.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      final overflow = drafts.length - maxDrafts;
      drafts.removeRange(0, overflow);
    }
    _pruneByMediaSize();
    drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    lastSavedAt.value = DateTime.now();
    _persist();
  }

  /// Save or update using partial form snapshot fields (convenience)
  PostDraft saveOrUpdateFromSnapshot({
    required String id,
    required Map<String, dynamic> formSnapshot,
    required List<String> imageBase64,
    String? originalVideoPath,
    String? compressedVideoPath,
    int? originalVideoBytes,
    int? compressedVideoBytes,
    bool usedCompressed = false,
    String? videoThumbBase64,
    bool phoneVerified = false,
  }) {
    final now = DateTime.now();
    final existing = drafts.firstWhereOrNull((d) => d.id == id);
    final draft =
        (existing ??
                PostDraft(
                  id: id,
                  createdAt: now,
                  updatedAt: now,
                  brandUuid: formSnapshot['brandUuid'] ?? '',
                  modelUuid: formSnapshot['modelUuid'] ?? '',
                  brandName: formSnapshot['brand'] ?? '',
                  modelName: formSnapshot['model'] ?? '',
                  condition: formSnapshot['condition'] ?? '',
                  year: _tryParseInt(formSnapshot['year']),
                  price: _tryParseDouble(formSnapshot['price']),
                  currency: formSnapshot['currency'] ?? 'TMT',
                  location: formSnapshot['location'] ?? '',
                  credit: formSnapshot['credit'] == true,
                  exchange: formSnapshot['exchange'] == true,
                  transmission: formSnapshot['transmission'] ?? '',
                  engineType: formSnapshot['engineType'] ?? '',
                  enginePower: _tryParseDouble(formSnapshot['enginePower']),
                  milleage: _tryParseDouble(formSnapshot['milleage']),
                  vin: formSnapshot['vin'] ?? '',
                  description: formSnapshot['description'] ?? '',
                  phone: formSnapshot['phone'] ?? '',
                  title: formSnapshot['title'] ?? '',
                  phoneVerified: phoneVerified,
                  imageBase64: imageBase64,
                  originalVideoPath: originalVideoPath,
                  compressedVideoPath: compressedVideoPath,
                  originalVideoBytes: originalVideoBytes,
                  compressedVideoBytes: compressedVideoBytes,
                  usedCompressed: usedCompressed,
                  videoThumbnailBase64: videoThumbBase64,
                  schemaVersion: 2,
                  videoPath: originalVideoPath, // legacy field for migration
                ))
            .copyWith(
              updatedAt: now,
              imageBase64: imageBase64,
              originalVideoPath: originalVideoPath,
              compressedVideoPath: compressedVideoPath,
              originalVideoBytes: originalVideoBytes,
              compressedVideoBytes: compressedVideoBytes,
              usedCompressed: usedCompressed,
              videoThumbnailBase64: videoThumbBase64,
              phoneVerified: phoneVerified,
            );
    upsert(draft);
    return draft;
  }

  /// Convenience wrapper taking immutable PostFormState (future integration)
  PostDraft saveFromFormState({
    required String id,
    required dynamic
    formState, // expects PostFormState type; kept dynamic to avoid circular import for now
    required List<String> imageBase64,
    String? originalVideoPath,
    String? compressedVideoPath,
    int? originalVideoBytes,
    int? compressedVideoBytes,
    bool usedCompressed = false,
    String? videoThumbBase64,
  }) {
    // Avoid importing PostFormState directly until controller migration complete.
    final map = (formState as dynamic).toMap() as Map<String, dynamic>;
    return saveOrUpdateFromSnapshot(
      id: id,
      formSnapshot: map,
      imageBase64: imageBase64,
      originalVideoPath: originalVideoPath,
      compressedVideoPath: compressedVideoPath,
      originalVideoBytes: originalVideoBytes,
      compressedVideoBytes: compressedVideoBytes,
      usedCompressed: usedCompressed,
      videoThumbBase64: videoThumbBase64,
      phoneVerified: map['phoneVerified'] == true,
    );
  }

  void delete(String id) {
    drafts.removeWhere((d) => d.id == id);
    _persist();
  }

  void clearAll() {
    drafts.clear();
    _persist();
  }

  PostDraft? find(String id) => drafts.firstWhereOrNull((d) => d.id == id);

  void _pruneByMediaSize() {
    // TODO: Implement total media size pruning policy (e.g., drop oldest large drafts)
  }

  int? _tryParseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    if (v is num) return v.toInt();
    return null;
  }

  double? _tryParseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    if (v is num) return v.toDouble();
    return null;
  }
}
