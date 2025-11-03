# Post Details Screen Optimization Summary

## 1. Background
The `PostDetails` screen currently displays a carousel of images (and potentially videos) for a single post. Prefetch behavior is basic:
- Initial: Prefetch first 3 images sequentially.
- Navigation: On page change, prefetch only the immediate next and previous image (±1) if not already prefetched.
- Telemetry exists globally via `CachedImageHelper` but no session-level snapshot or targeted instrumentation for the details view.

This results in occasional visible loading placeholders on rapid swipes and lacks adaptive behavior based on user navigation velocity or direction. There's also no guard against continued async work after controller disposal.

## 2. Current Gaps
| Area | Current State | Gap | Impact |
|------|---------------|-----|--------|
| Initial Warm | Sequential loop (first 3) | Non-batched, no parallelism | Slower first interaction readiness |
| Adjacent Prefetch | Fixed radius ±1 | Not adaptive or direction-aware | Missed opportunity to eliminate placeholders on fast swipes |
| Disposal Safety | No `_disposed` guard | Late futures may fire post-close | Potential wasted network & exceptions |
| Telemetry | Global cumulative | No per-session diff snapshot | Harder to tune specifically for details UX |
| Video Support | Undefined/ignored | No thumbnail prefetch | Possible flash on video slide entry |
| Network Adaptation | Static quality selection | No dynamic tier downgrade on slow networks | Higher data cost / latency in poor conditions |

## 3. Goals & Success Metrics
- 95%+ of carousel swipes show fully cached images (no placeholder shimmer).
- <120ms average decode/display latency for prefetched images.
- Zero image load futures started after controller `onClose` (verified via logging guard).
- Session telemetry artifact created each visit (contains hits, misses, avg load time, slow samples >600ms).
- Batch initial warm reduces first interaction missing rate to <5%.

## 4. Constraints & Assumptions
- Image URLs are stable and delivered with size variants (original/large/medium/small).
- `CachedImageHelper.prewarmCache(List<String>)` supports batch prefetch (parallel within internal constraints).
- Carousel indexes are 0-based and stable for the session.
- Videos (if present) have at least a poster/thumbnail path accessible similarly to photos (if not, Phase 4 will adapt with defensive checks).

## 5. Phase Overview
| Phase | Name | Scope | Primary Files |
|-------|------|-------|---------------|
| 0 | Baseline Snapshot | Add lightweight session start timestamp & capture initial telemetry | `post_details_controller.dart` |
| 1 | Batch Initial Warm & Disposal Guard | Replace sequential prefetch; add `_disposed` flag & guard | `post_details_controller.dart`, `CachedImageHelper` (if minor helper added) |
| 2 | Adaptive Direction-Aware Prefetch | Dynamic radius (±2 or ±3) based on swipe velocity & forward streak | `post_details_controller.dart` |
| 3 | Session Telemetry Snapshot | Capture delta telemetry on `onClose` and structured debug output | `post_details_controller.dart` |
| 4 | Video Thumbnail Prefetch & Network Sensitivity | Prefetch video thumbnails first; adjust quality tier if slow network | `post_details_controller.dart`, (optional network util) |
| 5 | Documentation & QA Hardening | Final doc updates, test checklist, metrics logging refinement | Markdown docs |

## 6. Detailed Phase Plans
### Phase 0: Baseline Snapshot (Read-Only)
- Add `_sessionStart = DateTime.now()` when details controller initializes.
- No behavior change yet; measure current placeholder rate manually.
- Logging: `debugPrint('[PostDetails] Baseline start for post $uuid')`.

### Phase 1: Batch Initial Warm & Disposal Guard
Changes:
- Replace `_prefetchInitialImages()` loop with: collect first N (configurable, default 4–5) image URLs and call `CachedImageHelper.prewarmCache(urls)`.
- Add `_disposed = false;` set to true in `onClose()`.
- Wrap all prefetch calls: `if (_disposed) return;` before scheduling futures.
- Acceptance: Initial carousel navigation (next 3–4 swipes) should show no shimmer 90%+ of time.

### Phase 2: Adaptive Direction-Aware Prefetch
Logic:
- Track `lastIndex`, `forwardStreak`, and instantaneous swipe velocity (approx via time delta between `setCurrentPage` calls).
- If forwardStreak ≥2 and velocity <250ms between swipes, prefetch radius expands to next 2–3 forward items and only 1 backward.
- If user reverses direction, reset `forwardStreak`, use symmetric ±1 for one transition.
- Guard: Do not exceed list bounds; skip already prefetched URLs.
- Acceptance: Rapid swiping across 6 images yields zero new shimmer after first 2 slides.

### Phase 3: Session Telemetry Snapshot
- At `onClose`, compute delta: call `CachedImageHelper.getTelemetry()` before & after (Phase 0 captured baseline).
- Derive session-specific metrics: `sessionHits = after.hits - baseline.hits`, etc.
- Emit structured log JSON-like string for future ingestion: `debugPrint('[PostDetailsTelemetry] {post: uuid, hits: x, misses: y, avgLoadMs: z, slowSamples: n}')`.
- (Optional) Accumulate slow sample URLs for investigation.

### Phase 4: Video Thumbnail Prefetch & Network Sensitivity
- If post has videos, attempt to prefetch thumbnails (field name TBD; defensive null checks).
- Introduce a simple network heuristic:
  - Capture first image load time; if >800ms and network not flagged as fast, downgrade quality selection (choose medium/small path in adaptive builder for subsequent prefetch).
- Provide a boolean flag `_networkSlow` inside controller; pass hint to helper if extensible.

### Phase 5: Documentation & QA Hardening
- Finalize this summary with actual measured metrics.
- Add test matrix (device classes: low-end Android, mid iOS, emulator, throttled network 3G).
- Prepare rollback instructions (see section 10).

## 7. Pseudocode Highlights
Initial Batch Prefetch:
```
void _prefetchInitialImages() {
  final urls = _photos.take(_initialWarmCount)
    .map((p) => p.bestPath)
    .whereType<String>()
    .where((u) => !_prefetchedUrls.contains(u))
    .toList();
  if (urls.isEmpty || _disposed) return;
  _prefetchedUrls.addAll(urls);
  CachedImageHelper.prewarmCache(urls);
}
```
Adaptive Prefetch:
```
void _prefetchAdaptive(int index) {
  if (_disposed) return;
  final forward = index > _lastIndex;
  forward ? forwardStreak++ : forwardStreak = 0;
  final radiusForward = (forward && forwardStreak >= 2 && _recentSwipeFast()) ? 3 : 1;
  final radiusBackward = (forward && forwardStreak >= 2) ? 1 : 2; // Bias forward
  final targets = <int>{};
  for (var i=1; i<=radiusForward; i++) targets.add(index + i);
  for (var i=1; i<=radiusBackward; i++) targets.add(index - i);
  final urls = targets
    .where((i) => i >= 0 && i < _photos.length)
    .map((i) => _photos[i].bestPath)
    .whereType<String>()
    .where((u) => !_prefetchedUrls.contains(u))
    .toList();
  if (urls.isEmpty) return;
  _prefetchedUrls.addAll(urls);
  CachedImageHelper.prewarmCache(urls);
  _lastIndex = index;
}
```

## 8. Testing Strategy
| Test | Steps | Expected |
|------|-------|----------|
| Baseline Swipe | Open details, swipe through 6 images quickly | Some shimmer on 2nd–4th initially (baseline) |
| Phase 1 Warm | Implement batch warm, reopen, swipe first 4 | No shimmer after first image 90%+ |
| Disposal Guard | Open then immediately close screen mid-prefetch | No late logs/errors referencing disposed controller |
| Adaptive Forward | Rapidly swipe forward across 8 images | No shimmer after 2nd image; prefetch log shows radius expansion |
| Direction Change | Swipe forward 3 then backward 2 | Backward swipes show minimal shimmer (cached) |
| Telemetry Snapshot | Open, interact, close | Structured telemetry log appears once, values plausible |
| Slow Network Simulation | Throttle network & measure quality adaptation | Medium/small variant chosen after detection |
| Video Thumbnail | Post with video(s), open details | First video slide loads without placeholder frame |

## 9. Metrics Collection
Manual for now via `debugPrint`. Potential extension: write to a local analytics buffer or emit events to existing logging infrastructure.
- Capture timestamps around image decode (if accessible via callbacks) or approximate using `DateTime.now()` pre/post prefetch future completion.
- Classify slow samples >600ms.

## 10. Rollback Strategy
- Each phase isolates changes; revert by restoring previous method body.
- Maintain git commits per phase: `feat(details-prefetch-phase1)`, `feat(details-prefetch-phase2)`, etc.
- If adaptive logic causes overfetch/load spike, disable by forcing radius=1 until tuned.
- Telemetry can be silenced by guarding with `if (kReleaseMode) return;` if needed.

## 11. Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Overfetching increases bandwidth | Cap max batch size & radius; respect `_disposed` early | 
| Race conditions on rapid open/close | `_disposed` guards & minimal microtask scheduling |
| Video thumbnails missing | Defensive null checks; skip silently |
| Network detection false positives | Require 2+ consecutive slow samples before downgrade |

## 12. Future Enhancements (Post-Plan)
- Prefetch heuristics informed by average user swipe speed over last 10 swipes.
- ML-based prediction of next likely image (if non-linear navigation emerges).
- Integration with global cache eviction policy prioritizing upcoming targets.
- Persist telemetry across sessions for aggregated performance dashboard.

## 13. Acceptance Criteria Recap
- Adaptive prefetch reduces placeholder incidence to <5% on rapid swipes.
- No post-disposal prefetch calls (verified by absence of disposal warning logs).
- Session telemetry log emitted exactly once per visit.
- Batch warm improves first 4 images readiness (no shimmer) in ≥90% cases.
- Video slides show no initial blank frame when thumbnails available.

---
Prepared: 2025-11-03
Author: Optimization Plan Automation
Next Step: Implement Phase 1 (Batch initial warm + disposal guard) after review.
