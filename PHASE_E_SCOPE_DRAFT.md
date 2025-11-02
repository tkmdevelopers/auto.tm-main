# Phase E Scope Draft (Resume & Memory Optimization)

Last Updated: November 3, 2025
Status: Draft (Pending Approval)

## 1. Objectives
Provide resilient upload resume after interruption and reduce peak memory usage during multi-photo posts while preserving current reliability and correctness.

## 2. Outcomes & Success Criteria
| Goal | Metric | Target |
|------|--------|--------|
| Resume reliability | Successful continuation without re-uploading completed parts | > 95% of interrupted tasks |
| Duplicate avoidance | Duplicated media after resume | < 1% (manual audit) |
| Peak memory reduction | RSS delta vs current baseline (3-photo set + video) | -30% for 10 photo scenario (after lazy encode) |
| Snapshot integrity | Corrupted snapshot load attempts | < 0.5% (log sampled) |
| User clarity | Users who understand resume prompt | Qualitative PASS (UX review) |

## 3. Scope (In)
- Snapshot schema v2 with explicit `version` field
- Persist per-photo encoded bytes only after first use (lazy encoding gate)
- Optional on-disk temp file alternative for large sets (>8 photos)
- Resume flow on app relaunch: detect incomplete tasks, offer resume vs discard
- Memory profiler marks for before/after measurement
- Guardrails: fallback to full restart if v2 snapshot parse fails

## 4. Scope (Out / Deferred)
- Video chunked/resumable upload (design only if needed)
- Remote telemetry export (Phase F candidate)
- UI granular per-photo retry after resume (future enhancement)

## 5. Snapshot Schema v2
```jsonc
{
  "version": 2,
  "taskId": "uuid",
  "postUuid": "post-uuid",
  "createdAt": 1730610900000,
  "videoUploaded": true,
  "uploadedPhotoIndices": [0,2,3],
  "photoAspectRatios": [1.33, 1.78, null],
  "photoWidths": [520,739, null],
  "photoHeights": [390,415, null],
  "lazyEncoded": false,          // flag: have we switched to lazy encoding pathway
  "pendingPhotos": [             // optional: raw or base64 only for not-yet-encoded items
    { "index": 1, "path": "/local/cache/img1.jpg" }
  ]
}
```

## 6. Implementation Steps
1. Add schema version constant & upgrade path
2. On load: detect v1 -> transform to v2 (inject `version:2`, `lazyEncoded:false`)
3. Introduce lazy encoding toggle path (Phase E flag `enableLazyEncoding`)
4. Implement just-in-time encode: encode photo immediately before upload; persist encoded result only after success
5. Large set optimization: if photo count > 8 and average size > 150KB, spill raw bytes to temp files to reclaim memory
6. Resume dialog: "Resume previous upload? (3/10 photos & video uploaded)" with Resume / Discard
7. Memory profiling marks: `phaseE_pre`, `phaseE_post_encode_photoN`, `phaseE_peak` for baseline comparison
8. Logging: snapshot upgrade events & memory deltas

## 7. Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Snapshot corruption mid-write | Resume failure | Atomic write temp + rename |
| Increased disk IO (temp files) | Performance slowdown | Only enable for large sets |
| Lazy encoding increases latency | Slight per-photo delay | Encode concurrently with previous photo upload (prefetch next) |
| Version drift | Parse errors | Central version check + fallback clear & log |

## 8. Open Questions
1. Max acceptable added per-photo latency? (Assume <80ms ok)
2. Do we need encryption for temp files? (Probably no for MVP)
3. Should we garbage collect old snapshots automatically on success? (Yes, delete after finalize)

## 9. Acceptance Test Matrix
| Test | Scenario | Expected |
|------|----------|----------|
| Resume basic | App kill after 2/5 photos | Upload resumes at photo 3 |
| Snapshot corruption | Inject invalid JSON | Fallback: discard snapshot, start fresh (log warning) |
| Lazy memory reduction | 10 photos baseline vs Phase E | Peak RSS reduced ≥30% |
| Temp spill trigger | 12 photos large size | Temp files created & cleaned after completion |
| Duplicate avoidance | Resume then complete | No duplicate media server-side |

## 10. Rollout Plan
Phase 1: Hidden flag, internal testing (baseline capture)  
Phase 2: Enable for >8 photo posts only  
Phase 3: General enable (if metrics positive)  

## 11. Metrics Collection
- Peak & average RSS (existing MemoryProfiler + new marks)
- Snapshot upgrade count & failures
- Resume success count / attempts ratio
- Lazy encoding average per-photo encode time (ms)

## 12. Next Actions
- [ ] Approve scope
- [ ] Implement schema version + upgrade
- [ ] Add flag & foundational plumbing
- [ ] Baseline memory capture (current state) document
- [ ] Implement lazy encode path
- [ ] Implement resume dialog & logic
- [ ] Temp file spillover (if still needed after lazy results)

---
END
