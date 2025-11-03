# Upload System Refactor Plan

**⚠️ UPDATED: November 2, 2025 - Post Phase 0 Testing**

## 1. Purpose
Bring the photo + video upload pipeline to production-grade quality: correct data contracts, resilient behavior, predictable performance, strong observability, and clear UX. This document guides phased execution.

## 🔄 MAJOR REVISION: Phase 0 Test Results

**Phase 0 Diagnostics Complete!** Real-world testing revealed:
- ✅ **Photos work perfectly** - No backend fixes needed (Phase 1 cancelled!)
- ❌ **Video uploads 100% failing** - FFmpeg missing on server (NEW P0 priority)
- ⚠️ **AspectRatio calculation missing** - Frontend fix needed

**See**: `PHASE_0_RESULTS_SUMMARY.md` for full findings.

## 2. Current Pain Points (UPDATED)

### 🔴 CRITICAL (Blocking Production)
- **FFmpeg/FFprobe missing on backend** - Video uploads fail with 500 error

### 🟡 MEDIUM (Quality Issues)
- **AspectRatio sent as null** - Frontend not calculating before upload
- Token refresh retry reuses stale Dio client (old Authorization header) - NOT TESTED YET
- Generic backend error responses; frontend messages not actionable

### ✅ RESOLVED (No Longer Issues)
- ~~Empty photo arrays~~ - **Photos working correctly!**
- ~~Inconsistent field names~~ - **Form data structure correct**
- ~~Missing metadata~~ - **Width/height captured correctly**

### ⏸️ DEFERRED (Performance Already Good)
- Memory spikes for multi-photo uploads - Only +2.5MB for 3 photos, acceptable
- Limited UX feedback - Photos upload in <500ms, current UI adequate

## 3. Guiding Principles
1. Correctness first: contract alignment before optimization.
2. Incremental delivery: each phase leaves the system better without regressions.
3. Observability over guessing: measure before tuning.
4. Resilience over optimistic assumptions: prepare for unstable networks.
5. Low coupling: isolate upload concerns from UI presentation layer.
6. Progressive enhancement: advanced features (pause/resume) built atop solid core.

## 4. Phase Breakdown (REVISED POST-TESTING + IMPLEMENTATION UPDATE)

| Phase | Title | Status | Priority | Core Goal |
|-------|-------|--------|----------|-----------|
| 0 | Deep Diagnostics | ✅ COMPLETE | - | Establish ground truth |
| A | Core Reliability & Cancellation | ✅ COMPLETE | - | Real cancellation + status validation |
| B | Auth & Idempotent Retry | ✅ COMPLETE | - | Token refresh + part tracking |
| C | Metadata & Structured Logging | ✅ COMPLETE | - | Correlation IDs + instrumentation |
| D | Concurrency Management | ✅ COMPLETE | - | Photo upload parallelism (limit=2) |
| **NEW** | **FFmpeg Installation** | ✅ **COMPLETE** | **P0** | **Enable video processing** |
| **NEW** | **AspectRatio Calculation** | ✅ **COMPLETE** | **P1** | **Complete photo metadata (dual fields)** |
| 1 | Backend Contract Alignment | ❌ **CANCELLED** | - | ~~Photos already working~~ |
| E | Resume & Memory Optimization | 📝 **SPEC DRAFT** | P2 | Lazy encoding + snapshot v2 |
| 2 | Frontend API Refactor | ⏸️ DEFERRED | P3 | Clean request builder (stable now) |
| 3 | Adaptive Concurrency | ⏸️ DEFERRED | P4 | Dynamic limits (current fixed=2) |
| 4 | Enhanced Resiliency | ⏸️ DEFERRED | P5 | Exponential backoff + retry limits |
| 5 | Remote Telemetry | ⏸️ DEFERRED | P6 | Export to analytics service |
| 6 | Advanced Memory Optimization | ⏸️ DEFERRED | P6 | Streaming/chunking (after Phase E) |
| 7 | Security Hardening | ⏸️ DEFERRED | P4 | File validation + rate limiting |
| 8 | UX Polish | ⏸️ DEFERRED | P5 | Per-photo status indicators |
| 9 | Documentation | ⏸️ ONGOING | P3 | Incremental updates |

## 5. Detailed Phase Specifications

### Phase 0 – Deep Diagnostics ✅ COMPLETE
**Status**: ✅ COMPLETE (November 2, 2025)

**Acceptance Criteria**: ALL MET ✅
- ✅ Captured successful photo upload session (3 photos)
- ✅ Captured failing video upload session (FFmpeg missing)
- ✅ Logged: endpoints, headers, form keys, sizes, correlation IDs, status codes
- ✅ Verified `/posts/me` response shape - **Photos working correctly!**

**Metrics Captured**:
- Photo upload duration: 167-474ms (avg 367ms)
- Memory impact: +2.5MB for 3 photos (108ms encoding)
- Video upload fails: 100% (FFmpeg missing)

**Key Findings**:
1. 🎉 Photos already working - no backend fixes needed!
2. 🔥 Video processing broken - FFmpeg not installed
3. ⚠️ AspectRatio sent as null - needs frontend calculation

**Documents**:
- `PHASE_0_DIAGNOSTIC_TEST_PLAN.md` - Full test details
- `PHASE_0_RESULTS_SUMMARY.md` - Executive summary
- `PHASE_0_TEST_QUICK_GUIDE.md` - Test execution guide

---

### NEW PHASE: FFmpeg Installation 🔴 URGENT (P0)
**Priority**: CRITICAL BLOCKER  
**Timeline**: Immediate (1 hour)

**Problem**:
```
Error: Failed to upload video: Cannot find ffprobe
POST /api/v1/video/upload 500 18083.049 ms
```

**Impact**: 100% video upload failure rate

**Required Action**:
```bash
# Windows Server
1. Download FFmpeg from https://ffmpeg.org/download.html
2. Extract to C:\ffmpeg
3. Add C:\ffmpeg\bin to system PATH
4. Restart backend service
5. Verify: ffprobe -version

# Linux Server
sudo apt-get update
sudo apt-get install ffmpeg
ffprobe -version

# Docker
Add to Dockerfile:
RUN apt-get update && apt-get install -y ffmpeg
```

**Acceptance Criteria**:
- [ ] FFmpeg installed on backend server
- [ ] `ffprobe -version` command succeeds
- [ ] Backend service restarted
- [ ] Test video upload returns 200 OK
- [ ] Video metadata extracted (duration, codec)

**Rollback**: Not applicable (new infrastructure)

**Estimated Time**: 30 minutes  
**Assigned To**: Backend/DevOps Team

---

### NEW PHASE: AspectRatio Calculation 🟡 (P1)
**Priority**: High (Quick Win)  
**Timeline**: After FFmpeg fix

**Problem**:
Frontend sends `aspectRatio: null` in all photo uploads despite having width/height.

**Evidence**:
```
[PHASE_0_PHOTO] Size: 24.8 KB | AspectRatio: null | Width: 520 | Height: 390
```

**Required Changes**:
```dart
// In image metadata extraction (before upload)
final aspectRatio = width / height;

// Include in form data
formMap['aspectRatio'] = aspectRatio;
formMap['metadata[aspectRatio]'] = aspectRatio;
```

**Location**: Likely in `upload_manager.dart` or image processing utility

**Acceptance Criteria**:
- [ ] Calculate aspectRatio from width/height
- [ ] Include in photo upload form data
- [ ] Verify in diagnostic logs: `AspectRatio: 1.33` (not null)
- [ ] Backend stores aspectRatio in database

**Rollback**: Remove calculation, send null (current behavior)

**Estimated Time**: 15 minutes  
**Assigned To**: Frontend Team

---

### Phase 1 – Backend Contract Alignment ❌ CANCELLED
**Status**: ❌ CANCELLED

**Original Goal**: Fix Sequelize includes for empty photo arrays

**Test Results**: Photos already working correctly! No backend fixes needed.

**Evidence from Phase 0**:
```javascript
photo: [{
  uuid: "dfae3960-7fce-48c5-bf84-52501d497272",
  path: { small: "...", medium: "...", large: "..." },
  originalPath: "uploads\\posts\\1762098149307-356044073.jpg",
  aspectRatio: [value present]
}]
```

**Conclusion**: Original analysis was incorrect. Current implementation is functioning properly.

**Action**: ✅ No work required. Phase cancelled.
- Ensure junction table columns (`photoUuid`, `postId`) match model definitions.
- Implement `extractMetadata(body)` to populate aspectRatio,width,height.
- Standardize success response: `{ success:true, photo:{...}}` / `{ success:true, video:{...}}`.
- Structured errors: `{ success:false, code, detail }`.
Acceptance Criteria: `/posts/me` returns non-empty populated `photos` array when uploads exist.
Risks: Medium (schema mistakes cause missing data).
Rollback: Revert migration branch; deploy previous stable build.

### Phase 2 – Frontend Upload API Refactor
Changes:
- Introduce `UploadContext` and `UploadMediaPart` models.
- Single set of form-data keys: `postId`, `file`, plus `aspectRatio`, `width`, `height`.
- Rebuild Dio client after token refresh; ensure Authorization header updated.
- Central error mapping (network/auth/retryable/fatal) with enum.
Tests: Unit tests for form map builder, token refresh retry, error classifier.
Risks: Medium (refactor touching central service).
Rollback: Keep legacy UploadService code path under feature flag.

### Phase 3 – Concurrency & Pipeline Integrity
Changes:
- Adaptive concurrency: `min(4, remainingPhotos)`; reduce to 2 for large (>2MB) images.
- Optional sequential fallback (feature flag) to debug ordering.
- Backpressure: await completion & memory release before next batch.
- Unified cancellation propagation.
Metrics: Throughput (MB/s), active tasks count.
Risks: Low if guarded by tests.
Rollback: Disable adaptive flag -> fallback to sequential.

### Phase 4 – Resiliency & Recovery
Changes:
- Per-part retry (up to 3, exponential + jitter; skip on 4xx except 429).
- Persist progress snapshot `{ uploadedPhotoUuids:[], videoUploaded:true/false }`.
- Idempotency: skip already uploaded photos on resume.
- Graceful abort sets explicit `cancelled` state.
Tests: Simulated network failure; restart continuation test.
Risks: Medium (state corruption if snapshot logic flawed).
Rollback: Disable persistence feature flag.

### Phase 5 – Observability & Telemetry
Changes:
- Client sends `X-Upload-Task` header; backend echoes and logs start/end.
- Structured server logs: `{ taskId, partType, status, durationMs }`.
- Client instrumentation: per-part duration, aggregate throughput.
- Optional debug overlay showing live metrics.
Metrics Flow: Console -> future remote aggregator.
Risks: Low.
Rollback: Disable debug overlay flag.

### Phase 6 – Performance & Memory Optimization
Changes:
- Lazy photo encoding: compress only right before dispatch.
- Pre-upload downscale (e.g., max width 1600) to reduce size.
- Release Uint8List buffers after successful upload (`bytes = Uint8List(0)` or null).
- Evaluate video chunking feasibility (scoped; design only if backend lacks support).
Metrics: Peak RSS pre/post (baseline vs optimized scenario with 8 photos).
Risks: Medium (image quality regressions if scaling misconfigured).
Rollback: Toggle lazy encoding flag off.

### Phase 7 – Validation & Security Hardening
Client:
- Validate MIME (image/jpeg, image/png), size (<10MB), dimensions (>64x64).
Server:
- Enforce accepted MIME; early reject oversize before processing.
- Rate limit uploads (e.g., 30 photos / 10 min / user).
- Prevent zip-bomb / recursive decode attempts.
Acceptance: Upload of invalid file returns actionable error code.
Risks: Low.
Rollback: Relax limits temporarily.

### Phase 8 – UX & Feedback Polish
Changes:
- Per-photo progress bars and status icons (pending/sent/failed/retrying).
- Aggregate bar showing total bytes & ETA.
- Thumbnail insert on success (using returned path).
- Error summary banner with retry button.
Acceptance: User can identify and retry failed photos individually.
Risks: Low.
Rollback: Hide enhanced widgets (fallback to old simple progress display).

### Phase 9 – Documentation & Hand‑off
Outputs:
- `UPLOAD_ARCHITECTURE.md` (sequence diagram + data models).
- Error Code Catalog.
- ADRs: concurrency strategy, retry policy, metadata handling.
- Runbook: diagnosing stuck uploads, clearing corrupted snapshot.
- Future roadmap: presigned URL migration, chunked resumable video.
Acceptance: New engineer can onboard and ship a small change within a day.

## 6. Metrics & Instrumentation
Core Metrics:
- Photo success rate (% per session)
- Avg part duration (ms)
- Concurrency level vs throughput (MB/s)
- Retry count distribution
- Peak memory usage (MB)
- Token refresh success ratio
- User-visible failure rate (per 100 uploads)

Collection Strategy:
- Phase 0: Verbose console logging.
- Phase 5: Structured log objects (JSON) & optional export.
- Future: Hook to remote telemetry pipeline.

## 7. Risk Matrix (High-Level)
| Risk | Phase | Mitigation |
|------|-------|------------|
| Data contract mismatch | 1 | Add schema tests before deploy |
| State corruption (resume) | 4 | Version snapshot key; fallback clear if parse fails |
| Memory regression | 6 | Benchmark before enabling; guard behind flag |
| Broken retry loop | 4 | Cap attempts & log decision tree |
| User confusion (new UI) | 8 | Gradual rollout via feature flag |

## 8. Feature Flags
| Flag | Purpose | Default |
|------|---------|---------|
| `enableAdaptiveConcurrency` | Adjust photo parallelism | false |
| `enableLazyEncoding` | Defer image compression | false |
| `enableUploadRecovery` | Resume partial uploads | false |
| `enableDebugUploadOverlay` | Show live metrics UI | false |
| `enableEnhancedProgressUI` | New per-photo UI | false |

## 9. Rollback Strategy
- Each phase merges behind its feature flags; production toggle off to revert behavior instantly.
- Maintain previous stable UploadService implementation until Phase 2 validated.
- Snapshot corruption fallback: detect invalid JSON, auto-clear and log.
- Log verbosity adjustable (DEBUG/INFO) via single config enum.

## 10. Sequencing & Dependencies
- Phase 0 → must precede all (data).
- Phase 1 → unlocks accurate frontend modeling.
- Phase 2 → enables safe concurrency & retries.
- Phase 3/4/5 build on stable refactored pipeline.
- Phase 6 optimizes after correctness and observability.
- Phase 7/8 polish and harden final system.
- Phase 9 finalizes knowledge capture.

## 11. Acceptance Criteria Summary
A table mapping each phase to at least one measurable deliverable (see phase sections) will be appended after Phase 0 completes with actual baseline metrics.

## 12. Glossary
- **Part**: A single media upload attempt (one photo or the video).
- **Task**: Entire upload session for a post (video + N photos).
- **Snapshot**: Serialized JSON of partial upload progress.
- **Throughput**: Aggregate effective upload speed across active parts.
- **Recovery**: Resuming after interruption without re-sending completed parts.

## 13. Next Immediate Action
Proceed with Phase 0 instrumentation (temporary verbose logs) and capture baseline.

---
*Authored: Refactor Plan v1.0*
