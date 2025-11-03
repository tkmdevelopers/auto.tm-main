# Post Details Screen Architectural Refactor Plan

## 1. Executive Summary
The current `PostDetailsScreen` + `PostDetailsController` implementation concentrates multiple responsibilities (data fetching, adaptive image prefetch, telemetry, network condition inference, UI composition, navigation, download handling, video ordering) inside two files, reducing readability and testability. Objective: Refactor into a layered, modular architecture WITHOUT removing or altering existing user-visible features or performance wins (prefetch, telemetry). Migration will be phased, safe, and reversible at each step.

## 2. Existing Feature Inventory (MUST Preserve)
- Image carousel with:
  - Page indicator dots
  - Tap to full-screen viewer (`ViewPostPhotoScreen`)
  - Video CTA overlay when `post.video` exists
  - Animated favorite heart toggle
- Status badge (pending / declined) + posted date
- Download diagnostics PDF (with progress + dynamic filename)
- Characteristics grid (dynamic pairs, icons)
- Seller comment section
- Comments preview (three latest) + "Show all" navigation + full comments page
- Price bar + Call button (phone launch, validation of '+993' skip)
- Adaptive image prefetch (initial batch + directional swipes)
- Network speed adaptation (reduced radius on slow network)
- Telemetry logging on dispose (cache hit/miss, success/fail, slow loads)
- Token refresh (406 handling) & re-fetch
- Video playback ordering logic (part-number sorting)

## 3. Pain Points / Issues
| Category | Issue | Impact |
|----------|-------|--------|
| Readability | ~800+ LOC screen file mixes UI + logic + inline widget classes | Hard to navigate, cognitive overload |
| Separation | Controller handles prefetch, telemetry, network analysis, media ordering, API calls directly | Single change risk surface, difficult testing |
| Testability | Direct `http` calls & GetX storage inside controller | Hard to unit test without side-effects |
| State Modeling | Ad-hoc `isLoading` + null checks for post | No explicit error/empty states, branching complexity |
| Duplication | Repeated style snippets, container paddings, icon sizes | Harder consistent theme updates |
| Extensibility | Adding a new section (e.g. financing, share) increases monolith size | Slower feature evolution |
| Prefetch Strategy | Logic embedded + evolving heuristics | Hard to benchmark/compare strategies |
| Telemetry Coupling | Logging inside controller lifecycle | No plug/unplug possibility |
| Error Handling | 406 handled, others silently swallowed | Limited observability |
| Magic Values | Thresholds (600ms, 800ms, 150ms) inline | Hard to tune centrally |

## 4. Target Architecture Overview
```
lib/screens/post_details_screen/
  domain/
    post_repository.dart          // Wrap http, map JSON -> Post
    image_prefetch_strategy.dart  // Interface + strategies
    image_prefetch_service.dart   // Coordinates strategy + cache helper
    telemetry_service.dart        // Decorator/aggregator
  controller/
    post_details_controller.dart  // Thin orchestration, exposes PostDetailsState
  presentation/
    post_details_screen.dart      // Orchestrator only: composes sections
    sections/
      media_carousel.dart
      action_overlay.dart
      meta_header.dart
      status_badge.dart
      download_button.dart
      characteristics_grid.dart   // extracted (rename from _DynamicCharacteristics)
      seller_comment_section.dart
      comments_preview_section.dart
      price_call_footer.dart
    components/
      page_indicator_dots.dart
      favorite_toggle_button.dart
      async_state_builder.dart
  model/
    post_model.dart               // (existing)
    post_details_state.dart       // sealed Loading | Ready(post) | Error(msg)
```

## 5. Refactor Goals & Constraints
- Zero functional regression; pixel-level changes permitted only for code cleanup (no UX shifts).
- Preserve performance: prefetch timings & adaptive heuristics maintained initially.
- Each phase builds on previous; one feature boundary at a time.
- Rollback ability: keep previous version reachable via Git tag per phase.
- Increase testability: repository + strategy injectable (DI via Get.put or constructor).
- Maintain telemetry output format until final consolidation.
- LOC targets:
  - `post_details_screen.dart` ≤ 250 LOC
  - `post_details_controller.dart` ≤ 300 LOC post extraction
- Introduce sealed-ish state (enum class or pattern) for clear UI branching.

## 6. Detailed Design Elements
### 6.1 State Modeling
`PostDetailsState`:
```dart
sealed class PostDetailsState {
  const PostDetailsState();
}
class PostDetailsLoading extends PostDetailsState { const PostDetailsLoading(); }
class PostDetailsReady extends PostDetailsState { final Post post; const PostDetailsReady(this.post); }
class PostDetailsError extends PostDetailsState { final String message; const PostDetailsError(this.message); }
```
Controller exposes `Rx<PostDetailsState>`.

### 6.2 Prefetch Strategy Abstraction
```dart
abstract class PrefetchStrategy {
  Set<int> computeTargets(int currentIndex, int itemCount, PrefetchContext ctx);
}
class AdaptiveMomentumStrategy implements PrefetchStrategy { /* logic moved here */ }
class ConservativeStrategy implements PrefetchStrategy { /* fallback */ }
class PrefetchContext { final bool networkSlow; final int forwardStreak; final bool fastSwipe; /* ... */ }
```
`ImagePrefetchService` holds cache of seen URLs and invokes `CachedImageHelper.prewarmCache()`.

### 6.3 Telemetry Service
Encapsulate session start, baseline capture, final delta logging. Controller calls `telemetryService.startSession(postId)` and `telemetryService.finishSession(postId)`.

### 6.4 Repository
`PostRepository.getPost(uuid)` performs http + token refresh fallback; maps JSON -> Post.
Benefits: isolates protocol & headers.

### 6.5 Presentation Decomposition
Each section gets a pure widget file with clear props.
- `MediaCarousel`: handles `CarouselSlider`, delegates overlay to `ActionOverlay`.
- `ActionOverlay`: back button, favorite toggle, video CTA, page dots (extracted `PageIndicatorDots`).
- `MetaHeader`: brand/model, posted date, status badge
- `DownloadButton`: uses injected `DownloadController` state
- `CharacteristicsGrid`: (extracted, replace `_DynamicCharacteristics`)
- `SellerCommentSection`
- `CommentsPreviewSection`
- `PriceCallFooter`

### 6.6 Testing Approach (Post Phases 1–5)
- Unit test `AdaptiveMomentumStrategy.computeTargets` edge cases.
- Unit test `PostRepository.getPost` token refresh path.
- Snapshot/widget test for `MetaHeader` + status permutations.

## 7. Phased Migration Plan
| Phase | Scope | Key Files | Acceptance Criteria | Rollback Tag |
|-------|-------|-----------|---------------------|--------------|
| 1 | Extract sectional widgets (no logic moves) | presentation/sections/* | Screen renders identically; controller unchanged; no perf change | `refactor-p1` |
| 2 | Move prefetch + network adaptation into `ImagePrefetchService` | domain/image_prefetch_service.dart | Controller slimmer; logs still appear; targets same for given swipes | `refactor-p2` |
| 3 | Introduce `PostDetailsState` sealed model | controller + screen | Loading shimmer, error placeholder (simulate by forcing failure), ready state; no lost features | `refactor-p3` |
| 4 | Create `PostRepository`; move fetch/token logic | domain/post_repository.dart | Controller delegates; test manual failure/refresh; same post data | `refactor-p4` |
| 5 | Implement strategy pattern for prefetch | domain/image_prefetch_strategy.dart | Strategy pluggable; default matches old behavior (snapshot tests pass) | `refactor-p5` |
| 6 | TelemetryService extraction | domain/telemetry_service.dart | Session summary identical string format; controller only calls start/finish | `refactor-p6` |
| 7 | Final cleanup + tests + docs | All | Tests passing; LOC targets met; README section added | `refactor-p7` |

## 8. Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Hidden coupling (controller assumes direct field access) | Incremental extraction; compiler guides missing imports |
| Performance regression in prefetch timing | Keep logic identical until Phase 5; measure before/after |
| Telemetry divergence | Preserve original formatting until final phase |
| Feature drift (favorite toggles breaks) | Snapshot visual & interaction check after Phase 1 |
| Token refresh edge case lost | Add unit test for repository refresh path |
| Comments preview regression | Do not touch comment files until after Phase 3 (state integration) |

## 9. Monitoring Checklist During Refactor
- [ ] Carousel loads first image immediately
- [ ] Prefetch logs appear after first load
- [ ] Video button visible only when video path present
- [ ] Favorite toggles persisted
- [ ] Download progress updates visually
- [ ] Status badge renders correct color when `status == null` vs false
- [ ] Characteristics icons align in responsive rows
- [ ] Seller description shows or '-' placeholder
- [ ] Comments preview limited to 3; "Show all" navigates
- [ ] Price & call button functional; invalid '+993' suppressed
- [ ] Telemetry log prints on dispose

## 10. Rollback Strategy
Each phase completion creates a git tag (`refactor-pN`). Rollback = `git checkout refactor-p(N-1)` then create hotfix branch. No destructive migrations to data models.

## 11. Implementation Priority Rationale
Order chosen to minimize risk: isolate presentation first (pure UI), then heavy logic extraction. State modeling before repository to reduce branching duplication. Strategy abstraction only after stable baseline. Telemetry last because it is passive.

## 12. Post-Refactor Opportunities (Future Enhancements)
- Add share button (deeplink) next to favorite
- Introduce skeleton loader variations for slow network
- Central ThresholdConfig (slow/fast ms) injection
- Add image error overlay (retry mechanism)
- Combine video & image items into unified media list with adaptive layout

## 13. Success Metrics
- LOC reduction: Screen file <250 LOC
- Controller complexity: cyclomatic <12 (from current high)
- Unit test coverage for repository & strategy ≥80%
- Prefetch hit rate unchanged (±2%) over synthetic navigation script
- Time-to-first-interaction unchanged (< baseline +20ms)

---
Prepared for implementation. Next step: Phase 1 extraction scaffold.
