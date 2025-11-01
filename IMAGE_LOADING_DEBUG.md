# Image Loading Debugging Guide

## Issue: White Blank Images Showing

### Changes Made:
1. ✅ Replaced white shimmer with grey loading indicator
2. ✅ Added comprehensive debug logging with emojis
3. ✅ Fixed width issue in post_item.dart (using SizedBox with double.infinity)
4. ✅ Enhanced error widget with text message
5. ✅ Added empty URL validation

### Debug Logs to Watch For:

When you run the app, check the console for these messages:

```
🖼️ Loading image: [URL]
⏳ Default placeholder for: [URL]
✅ Successfully loaded image
❌ Error loading: [URL] - Error: [error details]
```

### Common Issues & Solutions:

#### 1. If you see ⏳ (placeholder) but never ✅ (success):
**Problem:** Images aren't loading from server
**Check:**
- Is the API_BASE URL correct in .env file?
- Is the server running?
- Are the photo paths in the database valid?
- Check network connectivity

**Test:** Try the placeholder URL in browser:
```
https://placehold.co/400x250
```
If this loads, your network is fine.

#### 2. If you see ❌ (error) messages:
**Problem:** Images failing to load
**Common Errors:**
- `404`: Image file doesn't exist on server
- `SSL/TLS error`: Certificate issues
- `Connection refused`: Server not reachable
- `CORS error`: Web-specific issue

**Solution:**
```dart
// Check the full error in console
// Look for the error type and message
```

#### 3. If you see "Empty image URL":
**Problem:** photoPath is empty or null
**Check:**
- Are posts returning valid photo paths from API?
- Is the API response correct?

**Test in API:**
```bash
GET /api/v1/posts
# Check if photo_path field has values
```

#### 4. If you see NO logs at all:
**Problem:** Hot reload might not have applied changes
**Solution:**
```powershell
cd auto.tm-main
flutter run
# Or press 'R' in terminal for hot restart
```

### Quick Diagnostic Test:

Add this temporarily to home_controller.dart after fetching posts:

```dart
// After posts are loaded
if (posts.isNotEmpty) {
  debugPrint('First post photo: ${posts[0].photoPath}');
  debugPrint('Full URL would be: ${ApiKey.ip}${posts[0].photoPath}');
}
```

This will show you:
1. If photoPath exists
2. What the complete URL looks like

### Expected Behavior:

**Good Loading Sequence:**
```
🖼️ Loading image: https://your-api.com/uploads/photo123.jpg
⏳ Default placeholder for: https://your-api.com/uploads/photo123.jpg
✅ Successfully loaded image
```

**Error Sequence:**
```
🖼️ Loading image: https://your-api.com/uploads/photo123.jpg
⏳ Default placeholder for: https://your-api.com/uploads/photo123.jpg
❌ Error loading: https://your-api.com/uploads/photo123.jpg
   Error type: SocketException
   Error: Connection refused
```

### How to Fix Based on Logs:

| Log Pattern | Issue | Fix |
|-------------|-------|-----|
| Only ⏳, no ✅ or ❌ | Loading stuck | Check network, server status |
| ❌ with 404 | File not found | Check photo paths in database |
| ❌ with SSL error | Certificate issue | Update API to use valid SSL |
| ❌ with CORS | Web platform issue | Add CORS headers on server |
| "Empty image URL" | No photoPath | Check API response structure |
| No logs | Code not running | Hot restart required |

### Next Steps:

1. **Run the app:**
   ```powershell
   cd auto.tm-main
   flutter run
   ```

2. **Watch the console** for the debug logs

3. **Share the console output** with the specific error messages

4. **Test a single image URL** in your browser to verify it loads

### Quick Fix: Revert to Image.network

If you need images working immediately while debugging:

```dart
// In cached_image_helper.dart, temporarily replace CachedNetworkImage with:
return Image.network(
  imageUrl,
  fit: fit,
  width: width,
  height: height,
  errorBuilder: (context, error, stackTrace) {
    debugPrint('Image.network error: $error');
    return _buildErrorWidget(width, height);
  },
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return _buildShimmer(width, height);
  },
);
```

This will bypass cached_network_image and use standard Flutter image loading.
