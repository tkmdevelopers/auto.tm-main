# Testing Guide: Deleted User Handling

## Quick Test Steps

### Prerequisites
1. Backend server running (`npm run start:dev`)
2. Flutter app running on simulator/device
3. Admin access to delete users

### Test Case 1: Active User Gets Deleted

**Steps:**
1. Log in to the app with a test account
2. Navigate to any screen (Home, Favorites, Profile)
3. **From backend/database**: Delete the user record
   ```sql
   DELETE FROM users WHERE phone = '+99312345678';
   ```
4. **In the app**: Try any action:
   - Create a post
   - Add to favorites
   - Refresh profile
   - Post a comment

**Expected Result:**
- Red snackbar appears at top: "Account Deleted - Your account has been deleted by an administrator"
- App immediately redirects to login screen
- All local tokens cleared
- Cannot perform any authenticated actions

---

### Test Case 2: App Startup with Deleted User

**Steps:**
1. Log in to the app
2. Close the app (keep it in background)
3. Delete the user from database
4. Reopen the app

**Expected Result:**
- App shows loading spinner
- Tries to call `GET /auth/me`
- Receives 404 or 401 USER_DELETED
- Shows "Account Not Found" snackbar
- Redirects to login screen

---

### Test Case 3: Token Refresh Attempt

**Steps:**
1. Log in to the app
2. Wait for access token to expire (~15 minutes) OR manually expire it in database
3. Delete the user from database
4. Try any authenticated action

**Expected Result:**
- App attempts token refresh
- Refresh succeeds (token still valid)
- Next API call with new token fails with USER_DELETED
- User logged out immediately

---

## Manual Database Testing

### Check User Exists
```sql
SELECT uuid, name, phone FROM users WHERE phone = '+99312345678';
```

### Delete User
```sql
DELETE FROM users WHERE phone = '+99312345678';
```

### Check Related Data (should be SET NULL)
```sql
SELECT uuid, "userId" FROM posts WHERE "userId" IS NULL LIMIT 10;
SELECT uuid, "userId" FROM comments WHERE "userId" IS NULL LIMIT 10;
```

---

## API Testing with cURL

### 1. Get Access Token
```bash
# First, verify OTP
curl -X POST http://localhost:3000/api/v1/otp/verify \
  -H "Content-Type: application/json" \
  -d '{"phone": "+99312345678", "otp": "123456"}'
```

### 2. Test Authenticated Endpoint
```bash
# Should work normally
curl -X GET http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 3. Delete User in Database
```sql
DELETE FROM users WHERE phone = '+99312345678';
```

### 4. Retry Same Request
```bash
# Should return 401 USER_DELETED
curl -X GET http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# Expected response:
# {
#   "code": "USER_DELETED",
#   "message": "This account has been deleted by an administrator",
#   "statusCode": 401
# }
```

---

## Expected Error Responses

### USER_DELETED (New)
```json
{
  "code": "USER_DELETED",
  "message": "This account has been deleted by an administrator",
  "statusCode": 401
}
```

### User Not Found on /auth/me
```json
{
  "message": "User Not Found",
  "statusCode": 404
}
```

---

## Verification Checklist

- [ ] User sees clear error message when deleted
- [ ] User is immediately logged out
- [ ] App redirects to login screen
- [ ] Local tokens are cleared
- [ ] Cannot perform any authenticated actions
- [ ] Error appears on ALL authenticated endpoints
- [ ] Works on app startup
- [ ] Works during active session
- [ ] Works after token refresh

---

## Common Issues & Troubleshooting

### Issue: Error not showing
**Check:**
- Backend AuthGuard has USERS_REPOSITORY injected
- Frontend interceptor is registered in Dio
- Error code matches exactly: `USER_DELETED`

### Issue: User can still perform actions
**Check:**
- AuthGuard is applied to the endpoint (`@UseGuards(AuthGuard)`)
- Database user is actually deleted
- JWT token is being sent in request

### Issue: App crashes instead of logout
**Check:**
- `forceLogout()` is async and awaited
- Navigation routes are registered (`/register`)
- TokenStore is initialized

---

## Performance Verification

### Check Query Performance
```sql
EXPLAIN ANALYZE 
SELECT uuid FROM users WHERE uuid = 'some-uuid-here';
```

Expected: Index scan, < 1ms execution time

### Monitor Database Load
```sql
SELECT count(*) FROM pg_stat_activity 
WHERE state = 'active';
```

Should not significantly increase with this change.

---

## Rollback Instructions

If issues occur:

1. **Revert Backend**:
   ```bash
   cd backend
   git checkout HEAD -- src/guards/auth.gurad.ts
   git checkout HEAD -- docs/API_REFERENCE.md
   npm run start:dev
   ```

2. **Revert Frontend**:
   ```bash
   cd auto.tm-main
   git checkout HEAD -- lib/services/network/api_client.dart
   flutter clean
   flutter pub get
   ```

---

**Test Coverage Required**: All test cases should pass before marking as complete.
