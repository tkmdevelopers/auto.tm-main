# Future Improvements — Alpha Motors (auto.tm) Flutter App

This is a prioritized roadmap focused on stability, maintainability, and delivery speed.

---

## Guiding Principles

- Prefer small, testable refactors over large rewrites.
- Reduce cognitive load: remove dead code and unify duplicate implementations.
- Keep networking centralized in `ApiClient` + services.
- Preserve UX: drafts, retries, and offline handling are important.

---

## Roadmap (P0 → P3)

### P0 — Correctness & Cleanup (high ROI)

- Remove dead legacy auth implementation (`lib/services/auth_service.dart`) or rename it clearly as deprecated.
- Consolidate auth flow docs and code around **canonical** `lib/services/auth/auth_service.dart`.
- Fix font family mismatch (declared family vs. used family) to avoid inconsistent typography.
- Rename `lib/services/notification_sevice/` → `notification_service/` and update imports.
- Remove unused/commented-out code that creates confusion (`TextConstants`, commented NotificationController).

### P1 — Decompose Complexity Hotspots

- Split `PostController` into:
  - `PostFormController` (fields, validation)
  - `PostMediaController` (picker/compress)
  - `PostSubmitController` (submission orchestration)
- Split `UploadManager` into:
  - `UploadStateMachine` (phase transitions)
  - `UploadPersistence` (snapshot save/restore)
  - `UploadTransport` (API calls)
- Make `AppStyles` theme-aware (avoid hard-coded colors; pull from `Theme.of(context).colorScheme`).

### P2 — Testing & Quality Gates

- Add integration tests for:
  - OTP send/verify
  - token refresh interceptor behavior
  - auth-gated navigation tabs (Post/Profile)
  - post creation flow (without real media uploads; use mocks)
- Add CI checks:
  - `flutter analyze`
  - `flutter test`
- Remove `http` dependency if not used anywhere (keep only Dio).

### P3 — Product/Platform Enhancements

- Offline-first strategy for browsing (cache posts/categories locally).
- Accessibility and UX audit (semantics, contrast, touch targets).
- Performance profiling (startup time, memory) and remediation.

---

## Timeline (illustrative)

```mermaid
gantt
  title Alpha Motors Flutter — Improvement Plan
  dateFormat  YYYY-MM-DD
  axisFormat  %b %d

  section P0 Correctness & Cleanup
  Remove legacy AuthService file            :p0a, 2026-02-10, 7d
  Fix font-family mismatch                 :p0b, 2026-02-10, 3d
  Rename notification_sevice directory     :p0c, 2026-02-12, 5d
  Remove dead/commented code               :p0d, 2026-02-14, 5d

  section P1 Complexity Decomposition
  Split PostController responsibilities     :p1a, 2026-02-17, 14d
  Refactor UploadManager into modules       :p1b, 2026-02-20, 14d
  Theme-aware AppStyles                     :p1c, 2026-02-24, 10d

  section P2 Testing & Quality Gates
  Add integration tests (auth/refresh/nav)  :p2a, 2026-03-03, 14d
  Add CI gates (analyze + tests)            :p2b, 2026-03-10, 7d
  Remove unused http dependency             :p2c, 2026-03-12, 3d

  section P3 Platform Enhancements
  Offline-first browsing cache              :p3a, 2026-03-17, 21d
  Accessibility audit                       :p3b, 2026-03-24, 10d
  Performance profiling + fixes             :p3c, 2026-03-28, 14d
```

---

## Notes

- The P0 items are intentionally chosen to reduce confusion and prevent future regressions.
- The P1 refactors should be done with tests in place (or added alongside) to preserve behavior.
