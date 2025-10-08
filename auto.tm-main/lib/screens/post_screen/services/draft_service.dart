import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../model/draft_model.dart';

/// Service responsible solely for draft persistence, loading, pruning and CRUD.
/// Controller now becomes a thin intent emitter and state holder.
class DraftService extends GetxService {
  static const String _storageKey = 'POST_DRAFTS_V1';
  static const int maxDrafts = 10;
  final _box = GetStorage();

  final RxList<PostDraft> drafts = <PostDraft>[].obs;
  final RxBool isLoading = false.obs;
  final Rxn<DateTime> lastSavedAt = Rxn<DateTime>();

  Future<DraftService> init() async {
    await loadDrafts();
    return this;
  }

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
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void _persist() {
    _box.write(_storageKey, drafts.map((d) => d.toMap()).toList());
  }

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

  void delete(String id) {
    drafts.removeWhere((d) => d.id == id);
    _persist();
  }

  PostDraft? find(String id) => drafts.firstWhereOrNull((d) => d.id == id);

  void _pruneByMediaSize() {
    // Placeholder for future total size pruning; keep for parity with controller method.
  }
}
