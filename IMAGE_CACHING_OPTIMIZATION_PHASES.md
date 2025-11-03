# Image Caching & Display Optimization Phases

Status: Draft (v1)
Owner: Imaging / Performance Stream
Date: 2025-11-03
Scope: Flutter client image loading, caching, and display for feed cards, posted posts list, carousel (post details), full-screen viewer.
Out of Scope (initially): Backend image transformation endpoints (future Phase 4), video streaming optimizations, offline persistence beyond existing cache manager semantics.

---
## Objectives
1. Reduce decoded pixel waste (memory churn) while keeping visual sharpness.
2. Eliminate avoidable network latency (next/prev image wait, redundant fetches).
3. Stabilize layout (no jump / reflow) and improve perceived load (LQIP / instant aspect ratio placeholder).
4. Leverage numeric aspect ratio and width/height metadata for deterministic sizing & smarter cache dimension selection.
5. Establish measurable KPIs and automated regression detection hooks.

## Key Metrics & Targets (Initial)
| Metric | Baseline (Est / To Measure) | Target | Notes |
|--------|-----------------------------|--------|-------|
| Avg decoded pixels / feed image | TBD (~ width*height*multiplier= 600*200*6=720k logical ~ 4.3MP decode) | -40% | After DPR sizing rollout |
| Carousel swipe delay (cold next) | TBD (Subjective jank) | <50ms additional frame time | Prefetch ±1 |
| Layout shift (CLS proxy) | Non-zero (height fixed visually ok) | Maintain near-zero | AspectRatio placeholder to prevent future jank |
| First meaningful image paint | TBD | -20% | LQIP + fast primary fetch |
| Peak image memory (scroll 15 items) | TBD | -30% | Lower decode + reuse |
| Error rate (image load failures) | Current | No regression | Add telemetry hook |

## Phase Overview

### Phase 1: Quick Wins (Foundational Roll-in) ✅ COMPLETE
Goal: Remove high-risk over-decoding + add prefetch primitives without changing visual layout.
Actions:
- ✅ Replace hardcoded 4x/5x/6x multipliers with DPR-based `computeTargetCacheDimensions()` (DONE in `cached_image_helper.dart`).
- ✅ Add `CachedImageHelper.prefetch()` utility (DONE) & expose buildUrlForPrefetch helper.
- ✅ Integrate carousel next/prev prefetch in `PostDetailsController.setCurrentPage()` using new helper.
- ✅ Replace fixed width=600 in `PostItem` with `LayoutBuilder` actual width.
- ✅ Replace MediaQuery estimate in `PostedPostItem` with `LayoutBuilder` actual width.
Acceptance Criteria:
- No visual quality regression on standard & high DPI (manual QA: compare crispness). → **Pending QA**
- Average decoded pixel count reduction >= 30% (after measurement harness built). → **Pending measurement**
- No increase in image error logs. → **Monitoring recommended**
Risks: Under-sizing on unusual DPR (foldables). Rollback: revert to previous multiplier path (kept in git history).
Status: **Implementation complete** (2025-11-03). Ready for QA validation.

### Phase 2: Visual Stability & Perceived Performance ✅ COMPLETE
Goal: Predictable layout & faster perceived load.
Implemented:
- ✅ AspectRatio wrappers for feed & posted items (`computeAspectRatioForWidget`) eliminating layout jump.
- ✅ Faster fade-in (150ms) for perceived performance improvement.
- ✅ Consistent `BoxFit` policy documented (feed=cover, carousel=contain, full-screen=contain, avatars=cover).
- ✅ Enhanced neutral placeholder (`_EnhancedPlaceholder`) replacing shimmer + spinner.
Deferred / Future:
- LQIP (true blurred tiny preview) pending backend tiny variant/base64 support (Phase 4 tie-in).
Acceptance Evidence:
- Zero layout shift observed (see `PHASE_2_1_ASPECTRATIO_COMPLETE.md`).
- Placeholder & animation changes documented (`PHASE_2_COMPLETE.md`).
Risks: AspectRatio mismatch if server metadata inaccurate (mitigated by multi-source aspect ratio priority chain).

### Phase 3: Advanced Optimization & Bucketing ✅ COMPLETE (3.5 Validation Ongoing)
Goal: Normalize cache variants, reduce duplicate decodes, add observability & predictive loading.
Implemented & Integrated:
- ✅ Ratio bucketing adopted for feed (flag `ImageFeatures.useBucketedFeedAspectRatio`).
- ✅ Telemetry instrumentation + periodic 60s logging in `HomeController`.
- ✅ Pre-warm (initial batch) + scroll-driven adjacent prefetch with dedupe Set.
- ✅ Cache policy / LRU documentation.
Validation (3.5) In Progress:
- Gathering baseline vs bucketed hit rate, average load time, success rate (see `PHASE_3_QA_PLAN.md`).
Reference: `PHASE_3_COMPLETE.md` for full breakdown.

---

### Phase 4: Server-Side & Transformations (Future / Backend Needed)
Goal: Network byte size reduction & true responsive imaging.
Actions:
- Backend image resizing endpoint: parameters (w, q, format=webp/avif fallback jpeg).
- Client variant selection logic (choose next higher size bucket than needed, reuse).
- Conditional prefetch of WebP/AVIF with JPEG fallback negotiation via Accept header (if feasible).
- Integrate signed URL or cache-busting strategy for changed originals.
Acceptance Criteria:
- Average transferred bytes per image reduced by >= 40% vs original raw assets.
- No increase in decoding error rate.
Risks: CDN / caching complexity; image variant explosion (mitigate with bucketed widths only).

### Phase 5: Telemetry, Tooling & Guardrails
Goal: Continuous monitoring & regression prevention.
Actions:
- Add debug overlay toggle: shows displayed logical size vs decoded/cache size & ratio bucket.
- Build automated integration test capturing scroll performance & decode stats (profiling harness script).
- Alert if decodedPixels/displayPixels ratio > threshold (e.g., 3.5x) for > N images.
Acceptance Criteria:
- Dashboard with last 7d metrics for: avg decode ratio, failure rate, prefetch hit rate.
- CI gate to parse log snapshot and enforce decode ratio < limit.
Risks: Overhead from instrumentation (use sampling < 10%).

---
## Phase Interdependencies
- Phase 1 must complete before dynamic sizing (Phase 2) to ensure stable baseline.
- Phase 3 relies on accurate metrics instrumentation introduced end of Phase 2.
- Phase 4 depends on backend support; can proceed in parallel after Phase 2 if backend bandwidth available.

## Feature Flags / Toggles
| Flag | Purpose | Default |
|------|---------|---------|
| img_use_dpr_dimensions | Enable DPR cache dimension logic | ON |
| img_dynamic_aspect_ratio | Use AspectRatio wrappers | OFF (until Phase 2 QA) |
| img_lqip_placeholder | Show blurred low-res first | OFF |
| img_ratio_bucketing | Canonical size buckets | OFF |
| img_server_variants | Use backend resizing endpoints | OFF |
| img_telemetry_extended | Enable detailed decode metrics | OFF |

## Rollback Strategy
- Keep each phase behind flag(s).
- Single commit per phase core logic + docs for easy revert.
- Maintain compatibility: older snapshots still render with fallback fixed-height containers if flags off.

## Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|-----------|
| Incorrect ratio metadata leads to awkward heights | Medium | Clamp to min/max height; fallback to bucket ratio on outliers |
| Prefetch increases bandwidth on metered connections | Low | Skip prefetch when connection type = cellular & save-data active |
| LQIP causes perceived blur artifact complaints | Low | Fast fade (<120ms) + optional disable in settings |
| Telemetry overhead | Low | Sample 1 in 5 images; aggregate counters only |
| Server variant mismatch caching issues | High (Phase 4) | Use versioned URL path or hash query param |

## Open Questions
- Do we have access to network type (metered) for adaptive prefetch? (Investigate platform channels.)
- Should we unify shimmer removal across app concurrently or isolate to images only first?
- Will backend support WebP or AVIF generation pipeline (Sharp / libvips)?

## Initial Task Breakdown (Execution Backlog)
1. (P1) Integrate carousel prefetch in controller using new helper.
2. (P1) Replace magic width=600 in `PostItem` with `LayoutBuilder`.
3. (P1) Add helper `buildUrlForPrefetch` for clarity.
4. (P2) Implement AspectRatio flag usage (feed + posted posts).
5. (P2) Add simple in-memory LQIP (downscale after first frame) behind flag until backend.
6. (P3) Instrument decode metrics (wrap ImageStream listener) – sampling.
7. (P3) Implement ratio bucketing canonical sizes.
8. (P4) Draft backend spec for resizing endpoint.
9. (P5) Create debug overlay widget + telemetry exporter.

## Acceptance Review Checklist per Phase
- Code behind flag(s).
- Docs updated (this file + CHANGELOG section).
- Manual QA scenarios executed (list → details → full-screen → back navigation).
- Performance snapshot recorded (baseline vs post-change).

---
## Glossary
- LQIP: Low Quality Image Placeholder.
- Decoded Pixels: width * height of the bitmap actually decoded into memory.
- Display Pixels: rendered logical size * devicePixelRatio^2.
- Decode Ratio: decodedPixels / displayPixels (target <= 3.0 typical).

---
## Changelog
- 2025-11-03 (v1): Draft created; Phase 1 partial implementation already merged (DPR sizing + prefetch primitive).
- 2025-11-03 (v1.1): **Phase 1 complete** – Added buildUrlForPrefetch helper, integrated carousel prefetch in controller, replaced hardcoded widths with LayoutBuilder in PostItem & PostedPostItem. Pending QA validation.
- 2025-11-03 (v1.2): **Phase 1 refinement** – Added prefetch deduplication (Set tracking to prevent redundant requests during rapid swiping). Log analysis revealed backend not returning aspect ratio metadata (`nullxnull` in logs) – requires backend Photo serialization fix. See `PHASE_1_PREFETCH_ANALYSIS.md` for detailed findings.
- 2025-11-03 (v2.0): **Phase 2 complete** – AspectRatio wrappers, faster fade-in (150ms), enhanced neutral placeholder, BoxFit policy docs. See `PHASE_2_COMPLETE.md` & quick reference.
- 2025-11-03 (v2.1): **Phase 3 implementation (3.1–3.4) complete** – Ratio bucketing, telemetry, pre-warm & adjacent prefetch utilities, cache policy docs. Validation (3.5) pending integration of adjacent feed prefetch + telemetry baseline. See `PHASE_3_COMPLETE.md`.
