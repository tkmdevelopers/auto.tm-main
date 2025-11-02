# Backend Upload Flow Integration Analysis
Date: 2025-11-02

## 1. Purpose
Ensure the optimized client upload pipeline (Phases A–E: cancellation, token refresh, structured logging, concurrent photo uploads, lazy encoding + memory profiling) is fully aligned with current NestJS backend endpoints for post, photo, and video management. Identify mismatches, risks, and a validation plan before enabling lazy encoding and broader rollout.

## 2. Client Upload Flow (Final State)
Sequence:
1. Post creation (assumed existing endpoint) returns `postId`/UUID.
2. Video upload (optional) via `POST /v1/video/upload` field: `file` + body: `{ postId }`.
3. Photo uploads via `POST /v1/photo/posts` field: `file` (single) repeated per photo OR legacy `PUT /v1/photo/posts` with `files[]`.
4. Structured logging & correlation header `X-Upload-Task` attached to each multipart request.
5. Token refresh wrapper retries once on 401/406 and preserves idempotent state (skips already uploaded parts).
6. Recovery: On restart, previously marked uploaded indices/video flag skip re-upload.
7. Lazy encoding (feature-flagged) reduces memory footprint; persistence encodes to base64 for resilience.

## 3. Backend Endpoints Summary
| Resource | Method | Path | Field(s) | Notes |
|----------|--------|------|----------|-------|
| Video Upload | POST | `/v1/video/upload` | `file` | Validates duration (<=60s) in `VideoService.uploadVideo()`.
| Single Photo Upload | POST | `/v1/photo/posts` | `file`, body: `{ uuid: <postId> }` | Controller logs originalname + wraps into array for service.
| Multi Photo Upload | PUT | `/v1/photo/posts` | `files[]`, body: `{ uuid: <postId> }` | Uses `FilesInterceptor('files')`.
| Delete Photo | DELETE | `/v1/photo/posts/:uuid` | path param | Photo removal.

## 4. Multipart Field Mapping (Client → Backend)
| Client Part | Backend Expectation | Match | Action |
|-------------|---------------------|-------|--------|
| Video file | `file` | ✅ | No change.
| Photo file (single) | `file` | ✅ | Preferred path for simplified retries.
| Photo file (batch) | `files` | ✅ (legacy) | Still supported; keep for bulk admin tools only.
| Post UUID | body `uuid` | ✅ | Ensure always included.
| Photo metadata (aspect ratio, width, height, ratio, orientation) | `body.metadata.aspectRatio`, `metadata.width`, etc. | ✅ (service `extractMetadata`) | Confirm client sends nested `metadata[...]` form fields.
| Correlation header `X-Upload-Task` | Not currently consumed | ⚠️ | Optionally log in middleware for tracing.

### 4.1 Metadata Form Field Strategy
Client currently sends nested keys `metadata[aspectRatio]`, `metadata[width]`, `metadata[height]`, `metadata[ratio]`, `metadata[orientation]`.
Backend service uses `body.metadata`. Confirm NestJS body parser preserves bracket notation (if not, adjust client to send JSON field `metadata` with serialized JSON string). Action: Capture actual request payload sample and verify `body.metadata` shape.

## 5. Authentication & Token Refresh Alignment
Backend exposes refresh via `GET /v1/auth/refresh` guarded by `RefreshGuard`. Client wrapper refreshes tokens when upload gets 401/406. Validation Steps:
1. Force access token expiry mid-upload; ensure client refreshes once and resumes without duplicate media.
2. Backend should return 401 consistently for invalid/expired tokens (not 403 or custom codes). If other codes appear (e.g. 498), extend wrapper.
3. Ensure refresh endpoint latency doesn’t exceed upload cancellation timeout.

## 6. Idempotency & Recovery
Mechanisms:
- Client state: `uploadedPhotoIndices` & `videoUploaded` persisted.
- Retries skip already uploaded media to prevent duplicates.
Backend Considerations:
- Video uploads: Overwrites acceptable (single video per post). If multiple allowed, consider enforcing uniqueness server-side.
- Photos: Service currently always generates new UUIDs; no dedupe. Risk: In rare persistence crash window duplicates may appear.
Mitigations:
- Optional: Provide backend endpoint `/v1/photo/posts/existing?uuid=<postId>` returning count/hash list for stronger dedupe.
- Add client-side filename pattern including original index to allow backend collision detection.

## 7. Correlation & Observability
Client adds `X-Upload-Task=<uuid>` header.
Recommended Backend Enhancements:
- Add global NestJS middleware logging: `console.log('[UploadTrace]', req.method, req.path, req.headers['x-upload-task'])`.
- Persist correlation ID in video/photo DB rows (new nullable column `taskId`) for forensic tracing.
- Surface correlation ID in error responses for user support.

## 8. Error Handling Alignment
Client classification:
- Non-2xx → failure with status + truncated body.
- Cancellation → explicit cancelled state.
- Token refresh failures → propagate original error.
Backend responses:
- Photo: `res.status(200).json({ message: 'OK' })` or structured error with `message` + optional `error`.
- Video: success returns entity + `publicUrl`; failure throws generic Error (message only).
Actions:
- Standardize error responses (include `code`, `message`, optional `details`).
- Avoid plain 500 prints; add correlation header echo: `X-Upload-Task`.

## 9. Performance & Concurrency
Client concurrency limit: 2 photo uploads simultaneously.
Backend currently processes each request sequentially via Multer & Sharp.
Risk: CPU spikes resizing 2 large photos concurrently.
Mitigation:
- Evaluate average resize duration; if >1s each and CPU saturated, keep concurrency=1 for large posts (adaptive).
- Optionally implement server-side queue or rate limiting (429) → client backoff.

## 10. Memory Optimization Impact (Phase E)
Lazy encoding only affects client memory; backend receives identical multipart payload (raw file content). Persistence still stores base64 → no backend contract change.
Validation: Compare request bodies with flag on/off to confirm binary identical file bytes.

## 11. Validation & Test Matrix
| Area | Scenario | Expected Result | Tooling |
|------|----------|-----------------|---------|
| Auth Refresh | Expired token mid-photo sequence | Single refresh, no duplicate uploads | Staging script + token shortening |
| Idempotent Retry | Crash after 3/6 photos | Restart resumes at photo 4 | Simulated crash kill and relaunch |
| Correlation Header | All media requests | Header present server logs | Middleware log assertion |
| Metadata Mapping | Send aspect ratio | DB row has correct ratio + orientation | DB query after upload |
| Video Duration | Upload >60s video | 400 + error JSON; file deleted | Oversized test asset |
| Concurrency | 6 photo post | 2 parallel entries in server logs | Timestamp diff analysis |
| Lazy Encoding | Flag on/off diff | Identical backend file bytes | Hash comparison (server sha256) |
| Error Propagation | Force 500 in photo service | Client logs FAILURE with status | Mock failure injection |

## 12. Rollout Plan
Phased:
1. Backend middleware for correlation logging (no schema change).
2. Enable lazy encoding for internal testers only (`enableLazyEncoding=true` in debug build).
3. Collect memory + duration metrics for 7 days.
4. Add optional `taskId` column to photo/video tables (migration; backward compatible).
5. Full rollout of lazy encoding.
6. Evaluate need for photo dedupe endpoint based on duplicate incident rate (<0.5%).

## 13. Open Issues & Recommendations
| Issue | Recommendation |
|-------|---------------|
| Metadata bracket parsing uncertainty | Capture real request & confirm; fallback to JSON field if needed |
| Duplicate photo risk on crash window | Consider server-side hash + uniqueness constraint (postId + hash) |
| Missing standardized error schema | Introduce `{ code, message, details?, taskId? }` format |
| No correlation persistence | Add `taskId` column to video/photo for observability |
| Potential CPU spike with concurrency | Adaptive client concurrency based on first photo resize time |
| Token refresh path vs. other auth errors | Expand wrapper to treat 403/498 (if present) similarly |

## 14. Actionable Backend Changes Summary
- Add logging middleware for `X-Upload-Task`.
- Standardize error schema across controllers.
- Optionally add `taskId` field to media entities.
- Provide photo existence/dedupe endpoint (future, if needed).
- Return structured error for oversize video instead of generic Error.

## 15. Success Criteria
- All validation scenarios pass.
- Memory usage reduction verified (<30MB for 12 photos on mid-tier device).
- No increase in 5xx or media duplication incident rate post-rollout.
- Correlation IDs visible in logs for >95% media requests.

## 16. Next Steps
1. Implement backend logging & error schema.
2. Run validation matrix in staging.
3. Toggle lazy encoding in staging and gather metrics.
4. Review duplicate photo rate after 2 weeks.

---
Prepared by: Upload Optimization Task Force
