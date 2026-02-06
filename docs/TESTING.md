# Alpha Motors — Testing Guide

This document covers manual testing and smoke tests for the Alpha Motors stack. For backend unit/E2E tests, run `npm run test` and `npm run test:e2e` from `backend/`.

---

## 1. API Smoke Tests (Auth Flow)

Run against a local backend at `http://localhost:3080`. Full curl examples are in [backend/docs/API_REFERENCE.md](backend/docs/API_REFERENCE.md#curl-smoke-tests).

**Quick checks:**

1. **Health / Swagger:** `curl -s http://localhost:3080/api-docs | head -5`
2. **Send OTP:** `POST /api/v1/otp/send` with `{"phone":"99361999999"}` (test number)
3. **Verify OTP:** `POST /api/v1/otp/verify` with `{"phone":"99361999999","otp":"12345"}` → get `accessToken`, `refreshToken`
4. **Profile:** `GET /api/v1/auth/me` with `Authorization: Bearer <accessToken>`
5. **Refresh:** `POST /api/v1/auth/refresh` with refresh token → new pair
6. **Logout:** `POST /api/v1/auth/logout` with access token

---

## 2. Deleted User Handling

When an administrator deletes a user, the app must detect it and log the user out everywhere. The backend returns `401` with `code: "USER_DELETED"` on any authenticated request once the user no longer exists.

### Prerequisites

- Backend: `npm run start:dev` (or Docker) on port **3080**
- Flutter app running on simulator/device
- Admin access to delete users (e.g. direct DB or admin panel)

### Test Case 1: Active User Gets Deleted

1. Log in with a test account.
2. Navigate to any screen (Home, Favorites, Profile).
3. **From DB:** Delete the user, e.g.  
   `DELETE FROM users WHERE phone = '+99312345678';`
4. **In the app:** Perform any authenticated action (create post, add to favorites, refresh profile, post comment).

**Expected:** Red snackbar: "Account Deleted - Your account has been deleted by an administrator"; app redirects to login; local tokens cleared; no authenticated actions possible.

### Test Case 2: App Startup with Deleted User

1. Log in, then close the app (background).
2. Delete the user in the database.
3. Reopen the app.

**Expected:** Loading → `GET /auth/me` → 401 USER_DELETED or 404 → "Account Not Found" snackbar → redirect to login.

### Test Case 3: Token Refresh After Deletion

1. Log in.
2. Wait for access token to expire (~15 min) or expire it manually; delete the user in DB.
3. Trigger any authenticated action.

**Expected:** App tries refresh; next API call with new token gets USER_DELETED; user is logged out.

### Manual DB Checks

```sql
-- Check user exists
SELECT uuid, name, phone FROM users WHERE phone = '+99312345678';

-- Delete user
DELETE FROM users WHERE phone = '+99312345678';

-- Related data (e.g. posts/comments) may have userId SET NULL
SELECT uuid, "userId" FROM posts WHERE "userId" IS NULL LIMIT 10;
```

### cURL (Backend at 3080)

```bash
# Verify OTP and get tokens
curl -X POST http://localhost:3080/api/v1/otp/verify \
  -H "Content-Type: application/json" \
  -d '{"phone": "+99312345678", "otp": "12345"}'

# After deleting user, same request should return 401 USER_DELETED
curl -X GET http://localhost:3080/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
# Expected: { "code": "USER_DELETED", "message": "This account has been deleted by an administrator", "statusCode": 401 }
```

### Verification Checklist

- [ ] User sees clear "Account Deleted" (or "Account Not Found") message
- [ ] User is immediately logged out and redirected to login
- [ ] Local tokens are cleared
- [ ] No authenticated requests succeed
- [ ] Works on app startup, during active session, and after token refresh

### Troubleshooting

- **Error not showing:** Ensure AuthGuard has USERS_REPOSITORY injected; frontend Dio interceptor is registered; error code is exactly `USER_DELETED`.
- **User can still perform actions:** Ensure endpoint uses `@UseGuards(AuthGuard)`; user is actually deleted in DB; JWT is sent.
- **App crashes instead of logout:** Check `forceLogout()` is awaited; `/register` route exists; TokenStore is initialized.

---

## 3. Rate Limiting

From [API_REFERENCE.md](backend/docs/API_REFERENCE.md): OTP send is limited (e.g. 3 per 60s per IP + per-phone). Fourth request within the window should return **429**:

```bash
for i in 1 2 3 4; do
  curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:3080/api/v1/otp/send \
    -H 'Content-Type: application/json' -d '{"phone":"99361999999"}'
done
```

---

## 4. Rollback (Deleted User Feature)

If you need to revert deleted-user handling:

**Backend:**  
`git checkout HEAD -- backend/src/guards/auth.gurad.ts backend/docs/API_REFERENCE.md` then restart.

**Frontend:**  
`git checkout HEAD -- auto.tm-main/lib/services/network/api_client.dart` then `flutter clean && flutter pub get`.
