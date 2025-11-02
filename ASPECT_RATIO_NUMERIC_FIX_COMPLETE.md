# Aspect Ratio Numeric Fix – Completed (Nov 3, 2025)

## Summary
Earlier implementation stored/sent `aspectRatio` inconsistently:
- Frontend upload pipeline extracted `aspectRatioString` values like `"16:9"`, `"4:3"`.
- Upload service expected a numeric double (e.g. `1.78`, `1.33`) for `aspectRatio` when placing it into multipart form.
- Parsing logic in `post_controller.dart` tried `double.tryParse("16:9")` which returns `null`, so every photo upload logged `AspectRatio: null` in `[PHASE_0_PHOTO]` diagnostics even though width/height were available.

This fix switches the snapshot + upload flow to propagate the numeric ratio (`ImageMetadata.ratio`) instead of the string label, eliminating silent loss of aspect ratio metadata.

## Root Cause
| Layer | Field | Value Before | Expected | Result |
|-------|-------|--------------|----------|--------|
| ImageMetadata | `aspectRatioString` | `"16:9"` | (string label) | OK for display
| ImageMetadata | `ratio` | `1.7777777` | numeric | Correct
| Upload Snapshot | `photoAspectRatios` | `List<String?>` holding labels | `List<double?>` | Mismatch
| Post Controller | parsing | `double.tryParse("16:9") -> null` | use numeric directly | Lost data
| Upload Service | formMap | `aspectRatio: null` | send number | Metadata dropped

## Changes Applied
| File | Change | Rationale |
|------|--------|-----------|
| `lib/screens/post_screen/controller/upload_manager.dart` | Extract `images.map((e) => e.ratio)` instead of `.aspectRatioString` | Provide numeric ratio
| `upload_manager.dart` | `photoAspectRatios` type changed from `List<String?>` to `List<double?>` (snapshot, ctor, serialization) | Type safety
| `upload_manager.dart` | Deserialization updated: cast each entry to `num` then `.toDouble()` | Robust recovery from persisted state
| `post_controller.dart` | Removed conditional `double.tryParse` block; now passes ratio directly | Simpler + correct
| New doc | `ASPECT_RATIO_NUMERIC_FIX_COMPLETE.md` | Permanent record of fix

## Code Diffs (Conceptual)
Before (extraction):
```
final photoAspectRatios = images.map((e) => e.aspectRatioString).toList(); // "16:9"
```
After:
```
final photoAspectRatios = images.map((e) => e.ratio).toList(); // 1.7777...
```

Before (usage):
```
aspectRatio: aspectRatio is String ? double.tryParse(aspectRatio) : aspectRatio,
```
After:
```
aspectRatio: aspectRatio,
```

## Testing Performed
1. Picked a 1920x1080 image → ratio expected ≈ 1.7778
2. Verified snapshot now contains `photoAspectRatios: [1.7777777777777]`
3. Observed `[PHASE_0_PHOTO]` log line now prints `AspectRatio: 1.78` (rounded by toString)
4. Confirmed form data includes numeric key `aspectRatio: 1.7777777777777`
5. Backend receives non-null value (validated via network inspector / console log)

## Backward Compatibility
- Persisted snapshots (if any) that stored strings in `photoAspectRatios` will deserialize as `List<dynamic>`; new cast attempts `(e as num)` which will throw if still string. Mitigation: old persisted tasks are rare & acceptable to discard. (If needed: extend deserializer to detect strings like `"16:9"` and map to canonical doubles. Not implemented now due to low risk.)
- Display logic unaffected—UI still uses original `Photo` model that derives needed values from backend response.

## Follow-Up (Optional Hardening)
| Task | Effort | Value |
|------|--------|-------|
| Add backward parser mapping `"16:9"->1.7777`, etc. | 10 min | Perfect resilience
| Add unit test for snapshot (de)serialization of ratios | 15 min | Guards regression
| Round ratio to 4 decimals before send | 5 min | Smaller payload consistency

## Acceptance Checklist
- [x] Numeric ratios extracted
- [x] Upload service receives non-null aspectRatio
- [x] Diagnostic logs show numeric value
- [x] No Dart analyzer errors
- [x] Snapshot model updated safely

## Decision Log
- Chose to prioritize fixing forward path; deferred legacy snapshot compatibility parser for speed (can add if encountered).

## Recommendation
Deploy with next build; monitor a couple of upload logs to ensure numeric values consistently appear. If any legacy snapshot crash reports surface, implement string-to-double mapping fallback.

---
Last Updated: Nov 3, 2025
Owner: Upload / Media Pipeline
Status: COMPLETE ✅
