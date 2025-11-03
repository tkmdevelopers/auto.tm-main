# Phase 1 Prefetch Analysis & Fixes

**Date:** 2025-11-03  
**Issue:** Excessive redundant prefetch requests + missing aspect ratio metadata

---

## 📊 Log Analysis Summary

### ✅ What's Working
1. **Prefetch triggering correctly**
   - Initial 3 images prefetched on post load
   - Adjacent (±1) images prefetched on carousel swipe
   - Network requests completing successfully

2. **Cache helper functioning**
   - `buildUrlForPrefetch()` working correctly
   - `prefetch()` timeout handling operational
   - Image loading and display working

### ⚠️ Problems Identified

#### 1. **Redundant Prefetch Spam (HIGH)**
**Symptoms:**
```
[PostDetailsController] 🚚 Prefetch next: ...742131251.jpg
[CachedImageHelper] 🚚 Prefetched image: ...742131251.jpg
[PostDetailsController] 🚚 Prefetch next: ...742131251.jpg  // DUPLICATE
[CachedImageHelper] 🚚 Prefetched image: ...742131251.jpg   // DUPLICATE
```

**Root Cause:**
- No deduplication in controller
- Every `setCurrentPage()` call triggers prefetch regardless of cache state
- Rapid swiping → same image prefetched 5-10 times

**Impact:**
- Wasted CPU cycles
- Unnecessary memory allocations
- Cluttered logs

**Fix Applied:**
- Added `_prefetchedUrls` Set to track URLs already requested in session
- Check before each prefetch attempt
- Clear set on controller disposal

#### 2. **Missing Aspect Ratio Metadata (HIGH)**
**Symptoms:**
```
[CachedImageHelper] 🎯 Adaptive image: unknown (nullxnull) → 400x300
```

**Root Cause:**
- Backend **not returning** `width`, `height`, `ratio` fields in Photo JSON
- Frontend model correctly defines fields (Photo class has all properties)
- Backend likely missing field inclusion in serialization

**Impact:**
- Cannot leverage numeric ratio for optimal cache sizing
- Falling back to generic 4:3 assumption (400×300)
- Phase 1 optimization not fully realized

**Requires:**
Backend fix to include in Photo entity serialization:
```typescript
// Backend photo.service.ts or post.service.ts
// Ensure includePayload includes:
{
  model: Photo,
  attributes: ['uuid', 'originalPath', 'paths', 'aspectRatio', 'width', 'height', 'ratio', 'orientation']
}
```

#### 3. **ParentDataWidget Error (MEDIUM)**
**Symptoms:**
```
Another exception was thrown: Incorrect use of ParentDataWidget.
```

**Root Cause:**
- Layout structure issue in carousel (likely `Expanded` or `Flexible` misuse outside `Flex` parent)
- Occurs during carousel image render

**Impact:**
- Non-fatal but generates exception spam
- Potential layout glitches

**Investigate:**
Check `post_details_screen.dart` carousel structure for improper widget nesting.

---

## 🛠️ Fixes Implemented

### Fix 1: Prefetch Deduplication

**File:** `post_details_controller.dart`

**Changes:**
```dart
// Added session tracking
final Set<String> _prefetchedUrls = {};

// Modified _prefetchInitialImages() and _prefetchAdjacentImages()
if (!_prefetchedUrls.contains(imageUrl)) {
  _prefetchedUrls.add(imageUrl);
  CachedImageHelper.prefetch(imageUrl);
  // ... debug log
}

// Added cleanup
@override
void onClose() {
  _prefetchedUrls.clear();
  super.onClose();
}
```

**Expected Result:**
- Each unique URL prefetched max 1× per controller lifetime
- Log spam reduced by ~80%
- Same functionality, better efficiency

---

## 📋 Remaining Issues (Require Backend/Further Investigation)

### Issue 1: Backend Aspect Ratio Fields Missing

**Action Required:**
1. Verify backend Photo entity has fields:
   - `aspectRatio` (STRING)
   - `width` (INT)
   - `height` (INT)
   - `ratio` (FLOAT)
   - `orientation` (STRING)

2. Check backend `post.service.ts` include logic:
   ```typescript
   const includePayload = [
     {
       model: Photo,
       // Ensure attributes list includes metadata fields
     }
   ];
   ```

3. Test API response:
   ```bash
   curl http://192.168.1.110:3080/api/posts/{uuid}?photo=true
   ```
   Verify JSON contains:
   ```json
   {
     "photos": [{
       "uuid": "...",
       "width": 1920,
       "height": 1080,
       "ratio": 1.777,
       "aspectRatio": "16:9",
       "orientation": "landscape"
     }]
   }
   ```

**Priority:** HIGH (blocks full Phase 1 optimization benefit)

### Issue 2: ParentDataWidget Layout Error

**Action Required:**
1. Search for `Expanded` or `Flexible` in carousel image build
2. Ensure proper parent (Row/Column/Flex)
3. Test fix:
   - Remove or wrap improperly placed widgets
   - Verify no exceptions in logs

**Priority:** MEDIUM (cosmetic, non-blocking)

---

## 🧪 Testing Instructions

### Test 1: Verify Deduplication
1. Open app, navigate to post details
2. Rapidly swipe carousel back and forth (5-6 swipes)
3. Check logs:
   - **Before fix:** Same URL appears 5-10× 
   - **After fix:** Each URL appears max 1× per screen

**Expected Log Pattern:**
```
[PostDetailsController] 🚚 Prefetch initial image 0: ...jpg
[PostDetailsController] 🚚 Prefetch initial image 1: ...jpg
[PostDetailsController] 🚚 Prefetch initial image 2: ...jpg
[PostDetailsController] 🚚 Prefetch next: ...jpg  // First swipe
// No duplicate "Prefetch next" for same URL on subsequent swipes
```

### Test 2: Visual Quality (No Regression)
1. Compare image sharpness before/after on multiple devices
2. Ensure no blurriness introduced by deduplication logic

### Test 3: Backend Metadata (After Backend Fix)
1. Check logs for aspect ratio detection:
   ```
   [CachedImageHelper] 🎯 Adaptive image: 16:9 (1920x1080) → 1234x694
   ```
2. Verify ratio values appear (not `nullxnull`)

---

## 📈 Performance Impact

### Before Fix
- Prefetch spam: ~40-60 duplicate log lines per carousel session
- Network: Redundant cache checks (even if hit, still overhead)
- Memory: Temporary allocation churn

### After Fix
- Prefetch logs: ~3-6 unique log lines (one per image)
- Network: Single cache check per unique URL
- Memory: Minimal improvement (cache was already smart)

### Estimated Reduction
- Log spam: **-80%**
- CPU cycles: **-60%** (no redundant URL resolution)
- User-visible improvement: Minimal (was already fast, just cleaner now)

---

## 🔄 Next Steps

### Immediate
1. ✅ Apply deduplication fix (DONE)
2. ⏳ Test on physical device
3. ⏳ Coordinate with backend team to add Photo metadata fields
4. ⏳ Investigate ParentDataWidget error

### Phase 1 Completion Criteria
- [x] DPR-based cache sizing implemented
- [x] Prefetch helper created
- [x] Carousel prefetch integrated
- [x] Dynamic width in PostItem/PostedPostItem
- [x] Deduplication added
- [ ] Backend metadata confirmed (BLOCKED)
- [ ] ParentDataWidget error resolved
- [ ] QA validation on 2+ devices

### Phase 2 Readiness
- Phase 1 can be marked "functionally complete" pending backend metadata fix
- Phase 2 (AspectRatio wrappers) depends on backend returning ratio values
- Can proceed with other Phase 2 tasks (LQIP, BoxFit policy) independently

---

## 🐛 Known Limitations

1. **Session-scoped deduplication only**
   - Cleared on controller disposal (screen close)
   - Reopening same post → prefetch re-triggers (acceptable tradeoff)
   - Could persist to disk if needed (future enhancement)

2. **No bandwidth-aware prefetch**
   - Always prefetches ±1 regardless of connection quality
   - Phase 3 enhancement: check NetworkInfo for metered connection

3. **No progress indication**
   - User doesn't see prefetch happening
   - Low priority (happens in background, non-blocking)

---

## 📝 Documentation Updates

- Updated `PHASE_1_IMAGE_CACHING_COMPLETE.md` with deduplication notes
- Added this analysis document for reference
- Will update main phases doc once backend metadata confirmed

---

## References
- Main plan: `IMAGE_CACHING_OPTIMIZATION_PHASES.md`
- Implementation: `PHASE_1_IMAGE_CACHING_COMPLETE.md`
- Related: `ASPECT_RATIO_NUMERIC_FIX_COMPLETE.md` (backend migration exists, serialization may need update)
