# URGENT: Video Upload Fix - Action Guide

**Date**: November 2, 2025  
**Priority**: 🔴 P0 CRITICAL BLOCKER  
**Issue**: Video uploads failing with 100% failure rate  
**Root Cause**: FFmpeg/FFprobe not installed on backend server

---

## 🚨 Problem Summary

### What's Happening
```
Error: Failed to upload video: Cannot find ffprobe
at VideoService.uploadVideo (video.service.ts:144:13)
POST /api/v1/video/upload 500 18083.049 ms
```

### User Impact
- ✅ Video files upload successfully (network transfer 100% complete)
- ❌ Backend processing fails immediately with 500 error
- ❌ System retries 3 times, all fail (~55 seconds wasted)
- ❌ User sees "Upload failed" despite successful transfer

### Current Stats
- **Failure Rate**: 100%
- **Affected Feature**: All video uploads
- **User Experience**: Complete video upload blockage

---

## ✅ Solution: Install FFmpeg

### For Windows Server

```powershell
# 1. Download FFmpeg
# Go to: https://ffmpeg.org/download.html
# Download Windows build (e.g., ffmpeg-release-essentials.zip)

# 2. Extract to C:\ffmpeg
# Should have: C:\ffmpeg\bin\ffmpeg.exe and C:\ffmpeg\bin\ffprobe.exe

# 3. Add to System PATH
# Windows key -> "Environment Variables"
# System variables -> Path -> Edit -> New
# Add: C:\ffmpeg\bin

# 4. Verify Installation
ffprobe -version
# Should output version info

# 5. Restart Backend Service
# Stop Node.js/NestJS service
# Start it again to pick up new PATH

# 6. Test
# Upload a video through the app
```

### For Linux Server

```bash
# 1. Update package list
sudo apt-get update

# 2. Install FFmpeg (includes ffprobe)
sudo apt-get install -y ffmpeg

# 3. Verify Installation
ffprobe -version
ffmpeg -version

# 4. Restart Backend Service
# If using PM2:
pm2 restart auto-tm-backend

# If using systemd:
sudo systemctl restart auto-tm-backend

# If running directly:
# Stop current process and restart npm start

# 5. Test
# Upload a video through the app
```

### For Docker Deployment

```dockerfile
# Add to Dockerfile (before npm install)
RUN apt-get update && \
    apt-get install -y ffmpeg && \
    rm -rf /var/lib/apt/lists/*

# Then rebuild image:
docker-compose build backend
docker-compose up -d backend
```

### For macOS Development

```bash
# 1. Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install FFmpeg
brew install ffmpeg

# 3. Verify
ffprobe -version

# 4. Restart backend
# npm run start:dev (if using nodemon, it auto-restarts)
```

---

## 🧪 Testing the Fix

### 1. Verify FFmpeg Installation

```bash
# Check ffprobe is accessible
ffprobe -version

# Should output something like:
# ffprobe version 4.4.2 Copyright (c) 2007-2021 the FFmpeg developers
# built with gcc 9 (Ubuntu 9.4.0-1ubuntu1~20.04.1)
```

### 2. Check Backend Logs

```bash
# Backend should NOT show this error anymore:
# "Cannot find ffprobe"

# Should show successful video processing:
# "Video metadata extracted: duration=15.5s codec=h264"
```

### 3. Test Video Upload in App

1. Open app in debug mode
2. Create new post with video
3. Upload video file
4. Watch console logs:

**Before Fix (ERROR)**:
```
[UploadFlow] [FAILURE] partType=video status=500 error={statusCode: 500, message: Internal server error}
```

**After Fix (SUCCESS)**:
```
[UploadFlow] [COMPLETE] partType=video duration=XXXms
[UploadFlow] [TASK] event=TASK_COMPLETE
```

### 4. Verify in Database

```sql
-- Check video record created
SELECT * FROM videos WHERE "postId" = '[test_post_uuid]';

-- Should have:
-- - path: uploaded file path
-- - duration: extracted video duration
-- - codec: video codec info
```

---

## 📊 Expected Outcomes

### Before Fix
- ❌ Video upload: 500 error
- ❌ Retries: All fail
- ❌ User experience: Broken

### After Fix
- ✅ Video upload: 200 OK
- ✅ Metadata extracted: duration, codec, resolution
- ✅ Video playable in app
- ✅ User experience: Working

---

## 🔍 Troubleshooting

### Issue: "ffprobe: command not found"
**Solution**: PATH not updated. Close and reopen terminal, or restart backend service.

### Issue: "Permission denied"
**Solution Linux**: 
```bash
sudo chmod +x /usr/bin/ffprobe
sudo chmod +x /usr/bin/ffmpeg
```

### Issue: Still getting 500 error after install
**Checklist**:
1. ✅ Verify `ffprobe -version` works
2. ✅ Restart backend service completely
3. ✅ Check backend logs for any new errors
4. ✅ Ensure backend user has execute permissions

### Issue: Different error message now
**Action**: Check backend logs for new error details, may be different issue.

---

## ⏱️ Time Estimate

| Step | Time |
|------|------|
| Download/Install FFmpeg | 5-10 min |
| Configure PATH (if needed) | 2 min |
| Restart Backend | 1 min |
| Test Upload | 2 min |
| **TOTAL** | **10-15 min** |

---

## 📋 Checklist

### Installation
- [ ] FFmpeg downloaded/installed on server
- [ ] `ffprobe -version` command works
- [ ] PATH configured (Windows only)
- [ ] Backend service restarted

### Verification
- [ ] Test video upload returns 200 OK
- [ ] Video metadata visible in logs
- [ ] Video record in database
- [ ] Video playable in app

### Monitoring
- [ ] Check error logs for new issues
- [ ] Monitor video upload success rate (should be >95%)
- [ ] Test multiple video formats (mp4, mov, avi)
- [ ] Test various video sizes (1MB, 10MB, 50MB)

---

## 🎯 Success Criteria

✅ **Phase Complete When**:
1. FFmpeg installed and verified on production server
2. Test video upload succeeds (HTTP 200)
3. Video metadata extracted (duration, codec)
4. Zero "Cannot find ffprobe" errors in logs
5. Videos playable in app after upload

---

## 📞 Need Help?

### Backend Error Logs
```bash
# Check recent errors
tail -f /path/to/backend/logs/error.log

# Or if using PM2:
pm2 logs auto-tm-backend --err
```

### Video Service Code
Location: `backend/src/video/video.service.ts:144`

The service calls `ffprobe` to extract metadata. If ffprobe isn't in PATH, this line fails.

---

## 🚀 After Fix: Next Steps

Once video uploads work:

1. **Test AspectRatio Fix** (P1 - Frontend)
   - Calculate aspectRatio before photo upload
   - Verify in logs: not null

2. **Phase 2: Frontend Refactor** (P2)
   - Token refresh improvements
   - Error handling enhancement

3. **Monitor Production**
   - Video upload success rate
   - Average upload times
   - Any new error patterns

---

**Priority**: 🔴 DO THIS FIRST  
**Blocking**: All video functionality  
**Time Required**: ~15 minutes  
**Risk**: Low (adding missing dependency)
