# Backend Numeric Ratio Storage Validation

**Date**: November 3, 2025  
**Status**: Action Required (Backend Team)  
**Priority**: Medium

---

## 1. Context

Frontend now sends **dual aspect ratio fields** for photos:
- `ratio` / `metadata[ratio]`: Numeric value (e.g., `1.7778`)
- `aspectRatio` / `metadata[aspectRatio]`: String label (e.g., `"16:9"`)

This was implemented to fix null aspect ratio issues and provide both semantic (human-readable) and numeric (calculation-friendly) representations.

---

## 2. Current Frontend Implementation

### Upload Service (upload_service.dart)
```dart
if (aspectRatio != null) {
  // Send numeric ratio for backend 'ratio' column
  formMap['ratio'] = aspectRatio.toString();
  formMap['metadata[ratio]'] = aspectRatio.toString();

  // Derive and send string label for backend 'aspectRatio' column
  final label = _deriveAspectRatioLabel(aspectRatio);
  formMap['aspectRatio'] = label;
  formMap['metadata[aspectRatio]'] = label;
}
```

### Label Derivation Logic
```dart
String _deriveAspectRatioLabel(double ratio) {
  const tolerance = 0.04;
  const known = <String, double>{
    '16:9': 16 / 9,  // 1.7778
    '4:3': 4 / 3,     // 1.3333
    '1:1': 1.0,
    '9:16': 9 / 16,   // 0.5625
    '3:4': 3 / 4,     // 0.75
  };
  for (final entry in known.entries) {
    if ((ratio - entry.value).abs() <= tolerance) return entry.key;
  }
  return ratio.toStringAsFixed(2); // e.g., "1.78"
}
```

---

## 3. Expected Backend Behavior

### Photo Model Schema (Expected)
```typescript
// backend/src/photo/photo.model.ts or similar
{
  aspectRatio: string,  // Label: "16:9", "4:3", "1.78", etc.
  ratio: float,          // Numeric: 1.7778, 1.3333, etc.
  width: int,
  height: int,
  // ... other fields
}
```

### Metadata Extraction (Expected)
```typescript
// backend/src/photo/photo.service.ts or controller
function extractMetadata(body: any) {
  return {
    aspectRatio: body.metadata?.aspectRatio || body.aspectRatio || null,
    ratio: parseFloat(body.metadata?.ratio || body.ratio) || null,
    width: parseInt(body.metadata?.width || body.width) || null,
    height: parseInt(body.metadata?.height || body.height) || null,
  };
}
```

---

## 4. Validation Tasks

### Task 1: Verify Database Schema
**Action**: Check `photo` table schema.

**Expected Columns**:
```sql
aspectRatio VARCHAR(10)  -- Stores "16:9", "1.78", etc.
ratio FLOAT              -- Stores 1.7778, 1.3333, etc.
width INT
height INT
```

**If Missing**:
- Add `ratio FLOAT` column to photo table
- Create migration script
- Update Sequelize/TypeORM model

### Task 2: Verify Metadata Extraction
**Action**: Check photo upload controller/service.

**Test**:
1. Add temporary logging:
```typescript
console.log('[PhotoUpload] Received metadata:', {
  aspectRatio: body.metadata?.aspectRatio,
  ratio: body.metadata?.ratio,
  width: body.metadata?.width,
  height: body.metadata?.height,
});
```

2. Upload test photo
3. Check backend logs confirm both `aspectRatio` AND `ratio` present

**Expected Log**:
```
[PhotoUpload] Received metadata: {
  aspectRatio: '16:9',
  ratio: '1.7777777777777777',
  width: '739',
  height: '415'
}
```

### Task 3: Verify Database Storage
**Action**: Query database after test upload.

```sql
SELECT uuid, aspectRatio, ratio, width, height 
FROM photo 
ORDER BY createdAt DESC 
LIMIT 5;
```

**Expected Result**:
```
uuid                | aspectRatio | ratio    | width | height
--------------------|-------------|----------|-------|--------
e088dc54-fd43-...   | 16:9        | 1.7778   | 739   | 415
f19cfd0f-7e5f-...   | 4:3         | 1.3333   | 520   | 390
...
```

**If `ratio` Column Empty**:
- Metadata extraction not working
- Check if `body.metadata.ratio` vs `body.ratio` mapping correct
- Verify form-data parsing handles nested keys

### Task 4: Verify API Response
**Action**: Check GET `/posts/me` or similar endpoint.

**Expected JSON** (photo object):
```json
{
  "uuid": "e088dc54-fd43-4139-9830-781b8455379a",
  "path": { "small": "...", "medium": "...", "large": "..." },
  "aspectRatio": "16:9",
  "ratio": 1.7778,
  "width": 739,
  "height": 415
}
```

**If `ratio` Missing from API**:
- Add to Sequelize model attributes selection
- Ensure not excluded in `toJSON()` or serializer

---

## 5. Known Evidence (from Nov 3 logs)

### Frontend Confirms Sending Both Fields
```
[PHASE_0_PHOTO] FormData keys: [uuid, file, ratio, metadata[ratio], aspectRatio, metadata[aspectRatio], width, metadata[width], height, metadata[height]]
[PHASE_0_PHOTO] AspectRatio: 1.3333333333333333
```

### Backend Response Shows Label Only
```javascript
photo: [{
  uuid: "dfae3960-7fce-48c5-bf84-52501d497272",
  path: { small: "...", medium: "...", large: "..." },
  originalPath: "uploads\\posts\\1762098149307-356044073.jpg",
  aspectRatio: [value present]  // String label confirmed
}]
```

**Gap**: No `ratio` field visible in response → **needs verification**.

---

## 6. Acceptance Criteria

| Criterion | Status | Verification Method |
|-----------|--------|---------------------|
| `ratio` column exists in DB | ❓ | Check schema or run migration |
| Backend extracts `metadata[ratio]` | ❓ | Temporary log in controller |
| Database stores numeric ratio | ❓ | SQL query recent uploads |
| API returns `ratio` field | ❓ | GET /posts/me response |
| Frontend receives numeric ratio | ❓ | Client parse & use for calc |

---

## 7. Rollback Plan

If numeric ratio **not** needed by backend:
- Frontend already handles absence gracefully (falls back to width/height calc)
- Can remove redundant transmission later
- No breaking change; extra fields ignored

If numeric ratio **is** needed:
- Add migration ASAP before production data accumulates
- Backfill existing photos: `UPDATE photo SET ratio = width / height WHERE ratio IS NULL`

---

## 8. Next Actions

### Immediate (Backend Team)
- [ ] Check photo table schema for `ratio` column
- [ ] Add temporary logging to confirm metadata extraction
- [ ] Upload test photo and verify logs + database
- [ ] Update API response to include `ratio` field
- [ ] Remove temporary logging after confirmation

### Follow-up (Frontend Team)
- [ ] Once backend confirms, update monitoring checklist with "ratio population" metric
- [ ] Add backend ratio presence to Phase E dependencies (for lazy encoding)

---

## 9. Contact

**Issue Owner**: Frontend Lead  
**Backend Assignee**: TBD  
**Slack Channel**: #upload-system  
**Reference Docs**:
- `ASPECT_RATIO_NUMERIC_FIX_COMPLETE.md`
- `UPLOAD_DOCUMENTATION_INDEX.md`

---

**Status**: ⏳ Awaiting Backend Validation  
**Deadline**: Before Phase E implementation (lazy encoding depends on this)  
**Last Updated**: 2025-11-03
