# Testing the Comment Count Feature

## 🧪 Backend Testing

### 1. Start Backend Server
```bash
cd backend
npm run start:dev
```

### 2. Test the API Endpoint

#### Using PowerShell (Windows)
```powershell
# Replace <your-token> with actual JWT token
$token = "your-jwt-token-here"
$headers = @{
    "Authorization" = "Bearer $token"
}

Invoke-RestMethod -Uri "http://localhost:3000/api/v1/posts/me" -Headers $headers -Method Get | ConvertTo-Json -Depth 5
```

#### Using curl (if available)
```bash
curl -H "Authorization: Bearer <your-token>" http://localhost:3000/api/v1/posts/me
```

### 3. Expected Response
```json
[
  {
    "uuid": "abc-123",
    "price": 25000,
    "year": 2020,
    "status": true,
    "brand": { "name": "Toyota" },
    "model": { "name": "Camry" },
    "photo": [...],
    "commentCount": 3  // ← Should be a number
  }
]
```

### 4. Add Test Comments (Optional)

Create some test comments to verify counting:

```powershell
$body = @{
    message = "Test comment 1"
    postId = "your-post-uuid"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/api/v1/comments/create" `
    -Headers $headers `
    -Method Post `
    -Body $body `
    -ContentType "application/json"
```

## 📱 Flutter Testing

### 1. Hot Restart the App
Since we modified the model, do a full restart:
- Press `Shift + F5` (stop)
- Press `F5` (start)

Or use terminal:
```bash
cd auto.tm-main
flutter run
```

### 2. Navigate to Posted Posts
1. Open the app
2. Go to Profile tab
3. Tap on "My Posts" or similar

### 3. What to Look For

#### ✅ Success Indicators
- Comment preview appears below price/details
- Shows chat icon + count + arrow
- Only visible on **active** posts (status == true)
- Only visible if count > 0
- Tapping post navigates to details

#### ❌ Issues to Check
- No comment preview showing → Check backend response
- Shows "0 comments" → Should be hidden (check conditional)
- Layout broken → Check widget tree
- Crash on tap → Check navigation logic

### 4. Debug Output

Add temporary logging to verify data:

```dart
// In posted_posts_screen.dart, in itemBuilder:
print('Post ${post.uuid}: commentCount = ${post.commentCount}, status = ${post.status}');
```

Expected console output:
```
Post abc-123: commentCount = 5, status = true  // Should show preview
Post def-456: commentCount = 0, status = true  // Should hide preview
Post ghi-789: commentCount = 3, status = null  // Should hide preview (pending)
```

## 🐛 Troubleshooting

### Backend Issues

#### Error: "Cannot read property 'map' of undefined"
**Cause**: Posts query returned empty
**Fix**: Check if user has any posts in database

#### Error: GROUP BY related SQL error
**Cause**: Old code still running
**Fix**: Ensure server restarted after code changes

#### Error: commentCount is undefined
**Cause**: Comment count query failed
**Fix**: Check that Comments table exists and has postId foreign key

### Frontend Issues

#### Comment count not showing
1. Check backend response in network tab
2. Verify `PostDto.fromJson` is parsing correctly
3. Check conditional: `status == true && commentCount != null && commentCount! > 0`
4. Ensure `commentCount` parameter is passed to `PostedPostItem`

#### Shows on all posts (even inactive)
**Fix**: Check the conditional in `posted_post_item.dart` line ~310:
```dart
if (status == true && commentCount != null && commentCount! > 0)
```

#### UI looks wrong
**Fix**: Verify `_buildCommentPreview()` widget structure matches design

## 📊 Manual Database Check (Optional)

If you have direct database access:

```sql
-- Check total comments per post
SELECT "postId", COUNT(*) as comment_count
FROM comments
GROUP BY "postId";

-- Check comments for specific post
SELECT * FROM comments WHERE "postId" = 'your-post-uuid';

-- Check user's posts
SELECT uuid, status FROM posts WHERE "userId" = 'your-user-uuid';
```

## ✅ Final Verification Checklist

Backend:
- [ ] Server running without errors
- [ ] `/api/v1/posts/me` endpoint returns data
- [ ] Response includes `commentCount` field
- [ ] `commentCount` is a number (not string)
- [ ] Count matches actual comments in database

Frontend:
- [ ] App running without crashes
- [ ] Posted posts screen loads
- [ ] Comment preview shows on active posts with comments
- [ ] Preview hidden on pending/declined posts
- [ ] Preview hidden on posts with 0 comments
- [ ] UI looks clean and professional

## 🎯 Quick Test Scenario

1. **Create a test post** (via app or API)
2. **Add 2-3 comments** to that post (via app or API)
3. **Verify in API**: Call `/api/v1/posts/me` → Should show `commentCount: 3`
4. **Verify in UI**: Navigate to Posted Posts → Should see "3 comments" preview
5. **Tap the post** → Should navigate to post details
6. **Add another comment** in post details
7. **Go back** and pull to refresh Posted Posts
8. **Verify count updated** → Should now show "4 comments"

If all steps work, the feature is fully functional! 🎉
