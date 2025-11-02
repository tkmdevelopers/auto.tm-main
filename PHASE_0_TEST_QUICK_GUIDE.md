# Phase 0 Test - Quick Execution Guide

## 🚀 Quick Start (5 Steps)

### 1. Prepare Test Media
- Select **1 video** (~10-50MB)
- Select **3-5 photos** (different sizes/aspect ratios)

### 2. Open Console for Logs
In VS Code:
- Press `Ctrl+Shift+P` (Windows) or `Cmd+Shift+P` (Mac)
- Type "Flutter: Open DevTools"
- Select the "Logging" tab

### 3. Start Upload
1. Run the app in **Debug mode** (F5)
2. Login to your account
3. Go to Create Post screen
4. Select your prepared video and photos
5. Fill in brand, model, price, description
6. Tap "Submit" / "Upload"

### 4. Capture the Data
**While uploading, watch for these logs:**

```
[Phase0][Video] POST https://...
[Phase0][Video] taskId=... postUuid=... size=...
[Phase0][Video] formKeys=[...]
[Phase0][Video] Authorization=Bearer ...

[PHASE_0_PHOTO] Endpoint: https://...
[PHASE_0_PHOTO] TaskId: ... | PhotoIndex: 0 | PostUuid: ...
[PHASE_0_PHOTO] Size: ... KB | AspectRatio: ... | Width: ... | Height: ...
[PHASE_0_PHOTO] FormData keys: [...]
[PHASE_0_PHOTO] Auth token prefix: Bearer ...
```

**Copy ALL logs** - you'll paste them into `PHASE_0_DIAGNOSTIC_TEST_PLAN.md`

### 5. Verify Backend
After upload completes, test the API:
```bash
# Get your posts and check the photo array
GET /api/v1/posts/me
```

**Look for**: `"photo": []` (empty) vs `"photo": [{...}]` (populated)

---

## 📋 What to Document

### In PHASE_0_DIAGNOSTIC_TEST_PLAN.md, fill in:

#### Section: TEST RESULTS
- Paste all console logs under "Console Output - Video Upload"
- Paste each photo's logs under "Console Output - Photo Uploads"
- Include HTTP responses (look for response logging in console)

#### Section: Backend Database State
- Note the test post UUID from logs
- Query the database or use backend admin tools
- Paste the `/posts/me` response showing your test post

#### Section: Performance Metrics
- Note timestamps to calculate durations
- Record file sizes from the logs
- Fill in the metrics table

#### Section: ANALYSIS & FINDINGS
- **Issue 1**: Is the photo array empty? (Expected: YES)
- **Issue 2**: Do form keys match what backend expects?
- **Issue 3**: Is metadata saved (aspectRatio, width, height)?
- Document any other unexpected behavior

---

## ✅ Success Checklist

After the test, you should have:
- [ ] Complete console logs captured
- [ ] All HTTP responses documented
- [ ] Backend verification (database or API response)
- [ ] Performance metrics recorded
- [ ] Confirmed whether photo array is empty
- [ ] Identified any additional issues

---

## 🎯 Expected Outcome

**What we expect to find:**
1. ✅ Video uploads successfully
2. ✅ Photos upload successfully
3. ❌ **Photo array is EMPTY** in `/posts/me` response (the bug!)
4. ✅ Diagnostic logs show correct form data being sent
5. ❌ Backend Sequelize include is broken (string array instead of objects)

**This will confirm** the issues we identified in analysis and give us **real evidence** to fix in Phase 1.

---

## 🔧 If Something Goes Wrong

### Upload Fails
- Check network connection
- Verify authentication token is valid
- Look for error messages in console
- Document the error - it might reveal other issues!

### No Diagnostic Logs
- Confirm app is in **Debug mode** (not Release)
- Check `kDebugMode` is true
- Look in the right console (Flutter DevTools Logging tab)

### Can't Access Backend
- Use app's UI to verify upload appears in "My Posts"
- Check if photos show up in the uploaded post
- Document what you see in the app UI

---

## 📞 Next Steps

After you complete the test:
1. Fill in all sections of `PHASE_0_DIAGNOSTIC_TEST_PLAN.md`
2. Share your findings (or just say "test complete")
3. We'll analyze the results together
4. Then proceed to **Phase 1: Backend Contract Alignment** with concrete evidence

---

**Ready to test?** Just run the app, do an upload, and capture those logs! 🎬
