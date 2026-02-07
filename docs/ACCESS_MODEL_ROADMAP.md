# Roadmap: Access Model & Token Store Alignment

This roadmap covers **implementing the public vs authenticated access model** ([ACCESS_MODEL.md](ACCESS_MODEL.md)) and **verifying TokenStore** as the single source of truth. It includes an **alignment audit** of the current mobile app against this structure.

---

## 1. Current Mobile App vs Target (Alignment Audit)

### 1.1 Entry flow

| Aspect | Current state | Target (ACCESS_MODEL) | Aligned? |
|--------|----------------|------------------------|----------|
| **Initial route** | `initialRoute: '/navView'` in `main.dart` — app starts on main app (bottom nav), not on auth check. | Allow guest to reach main app without token. | ✅ Yes — guests already land on navView. |
| **Route `/`** | `AuthCheckPage`: if no token → `/register`; if token → validate `GET /auth/me` → `/navView` or clear and go to `/register`. | Optional: use `/` only when product wants an explicit “splash + auth check” before main app. | ⚠️ Partial — `/` is not used as initial route; if you ever set `initialRoute: '/'`, guests would be sent to register. For guest-first, keep initial route as `/navView` or add “Browse as guest” from `/`. |

**Conclusion:** Current app already allows guests into the main app (navView). No change required for entry unless you want a dedicated splash/auth screen with “Browse as guest” vs “Log in”.

### 1.2 Tab / screen gating

| Screen / tab | Current state | Target | Aligned? |
|--------------|----------------|--------|----------|
| **Home (0)** | No token check; loads posts via ApiClient.dio (public GET posts). | Public. | ✅ |
| **Favourites (1)** | No token check in navbar; screen uses ApiClient for `posts/list` (public). Favorites UUIDs from GetStorage. | Guest can view; “Add to favorites” should prompt login. | ✅ Structure OK; ensure “add to favorites” on post detail prompts login when no token. |
| **Post (2)** | `PostCheckPage`: if no token → show “register or login to continue”. Navbar redirects to `/register` when tapping Post tab if no token. | Token required to post. | ✅ |
| **Blog (3)** | No token check in navbar. Blog list/detail may call APIs; some backend vlog endpoints public (GET list), GET by id protected. | Public read; create post = token. | ⚠️ If blog detail uses GET vlog/:id, guest will get 401 until backend makes it public. |
| **Profile (4)** | `ProfileCheckPage`: if no token → show “register or login”. Navbar redirects to `/register` when tapping Profile if no token. | Token required. | ✅ |

### 1.3 TokenStore usage

| Item | Current state | Target | Aligned? |
|------|----------------|--------|----------|
| **Single source of truth** | Tokens stored only in `TokenStore` (flutter_secure_storage). No GetStorage for ACCESS_TOKEN/REFRESH_TOKEN (profile logout fallback fixed). | One place for tokens. | ✅ |
| **Who reads/writes tokens** | AuthService (OTP success) and ApiClient (refresh, force logout) write to TokenStore. ApiClient interceptor reads for attach/refresh. filter_controller, post_controller, blog use ApiClient.dio. | All auth flows via TokenStore; all API calls via ApiClient.dio so refresh/USER_DELETED handled in one place. | ✅ |
| **TokenService** | Deprecated wrapper around TokenStore. | Remove when no callers. | ✅ Optional cleanup. |

### 1.4 Public vs protected API calls

| Area | Current | Note |
|------|---------|------|
| Home (posts list) | ApiClient.dio.get('posts') | Public; no token sent if none. ✅ |
| Banners, categories | ApiClient.dio | Public. ✅ |
| Post detail | ApiClient.dio.get('posts/:uuid') | Public. ✅ |
| Comments (post detail) | ApiClient.dio.get('comments') | Public; guests can see comments. Done (Phase A1). ✅ |
| Favorites (posts/list) | ApiClient.dio.post('posts/list') | Public. ✅ |
| Search / brands | ApiClient.dio | Public. ✅ |
| Filter, post_controller, blog | ApiClient.dio | Migrated; all use ApiClient.dio. ✅ |

**Summary:** Structure aligns with “guest can browse main app and use public endpoints.” Backend GET comments is public (Phase A1). Key controllers (filter, blog, post) use ApiClient.dio. Optional: “Add to favorites” / “Comment” on post detail prompt login when no token (C1 done).

---

## 2. Roadmap (Ordered)

### Phase A: Backend (public access)

- [x] **A1.** Remove `AuthGuard` from `GET /comments` (and optionally `GET /comments/:id`) so guests can read comments. Keep AuthGuard on POST/PATCH/DELETE.
- [x] **A2.** (Optional) Remove `AuthGuard` from `GET /vlog/:id` so guests can read a single vlog.
- [x] **A3.** Verify no other read-only catalog endpoints incorrectly require auth (see [ACCESS_MODEL.md](ACCESS_MODEL.md) §4).

### Phase B: Flutter — TokenStore and API client

- [x] **B1.** Confirm no remaining GetStorage use for tokens (already done in profile logout fallback).
- [x] **B2.** Migrate remaining authenticated calls to ApiClient.dio: filter_controller, blog_controller, add_blog_controller, add_blog_screen, post_controller (see [ROADMAP.md](ROADMAP.md)). This gives consistent refresh and USER_DELETED handling and keeps TokenStore as the only token source used by the client.
- [ ] **B3.** (Optional) Remove or thin TokenService once no callers use it.

### Phase C: Flutter — Guest UX and protected actions

- [x] **C1.** Post detail: when user has no token and taps “Comment” or “Add to favorites”, show a clear “Log in to comment” / “Log in to save favorites” and navigate to `/register` (or bottom sheet with login CTA). Optionally hide or disable comment input and favorite button when guest.
- [x] **C2.** If comments are loaded on post detail: once backend makes GET comments public (A1), guests will see comments; else keep current behavior or skip loading comments when no token and show “Log in to see comments”.
- [ ] **C3.** (Optional) If you want an explicit “auth vs guest” choice at startup: set `initialRoute: '/'`, and in AuthCheckPage add “Browse as guest” → `/navView` and “Log in” → `/register`. Otherwise keep `initialRoute: '/navView'`.

### Phase D: Docs and verification

- [x] **D1.** After A1–A2, update [ACCESS_MODEL.md](ACCESS_MODEL.md) backend checklist and §4 (Comments/Vlog rows).
- [x] **D2.** After C1–C2, update [ACCESS_MODEL.md](ACCESS_MODEL.md) frontend checklist.
- [ ] **D3.** Manual test: cold start → browse home, filter, open post, (after A1) see comments; tap Post tab → register prompt; tap Profile tab → register prompt; log in → post, comment, favorites work.

---

## 3. TokenStore Verification Checklist

Use this to confirm the app structure aligns with “single token store, used everywhere for auth.”

- [x] TokenStore is the only place that stores ACCESS_TOKEN, REFRESH_TOKEN, USER_PHONE (secure storage).
- [x] No GetStorage (or other storage) writes/reads for access/refresh token (profile logout fallback fixed).
- [x] AuthService saves tokens to TokenStore on OTP success.
- [x] ApiClient reads TokenStore for attach and refresh; writes new tokens on refresh; clears on force logout.
- [x] Boot/session check uses TokenStore.hasTokens and ApiClient for GET /auth/me.
- [x] All authenticated HTTP requests go through ApiClient.dio (filter_controller, blog_controller, add_blog_controller, add_blog_screen, post_controller migrated).
- [x] Protected screens (Post, Profile) gate on TokenStore.hasTokens and redirect to register when missing.
- [x] TokenService is deprecated and delegates to TokenStore; no new code should use TokenService for tokens.

---

## 4. Dependency Overview

```
Phase A (Backend)     →  Phase C (Guest UX): C2 depends on A1 (comments public).
Phase B (ApiClient)   →  Improves reliability for all authenticated flows; independent of A/C.
Phase C (Guest UX)    →  Can be done in parallel with B; C2 best after A1.
```

---

## 5. References

- Access model (design, diagrams, API matrix): [docs/ACCESS_MODEL.md](ACCESS_MODEL.md)
- Auth/API migration (ApiClient, TokenStore): [docs/ROADMAP.md](ROADMAP.md)
- Backend architecture: [backend/docs/ARCHITECTURE.md](backend/docs/ARCHITECTURE.md)
