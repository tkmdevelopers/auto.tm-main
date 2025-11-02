# Monitoring Checklist (Upload System)

Last Updated: November 3, 2025
Status: Draft (Operational Baseline Pending)

## 1. Purpose
Establish minimal actionable monitoring for media uploads to quickly detect regressions in reliability, performance, and metadata integrity.

## 2. Core Metrics
| Category | Metric | Definition | Target | Collection Method |
|----------|--------|-----------|--------|------------------|
| Reliability | Photo Success Rate | Successful photos / attempted | > 98% | Parse client logs (UploadLogger COMPLETE) |
| Reliability | Video Success Rate | Successful videos / attempted | > 95% (multi-format) | Client log + server status aggregation |
| Metadata | Ratio Population | Photos with ratio & label | > 95% | Log sample / server DB query |
| Metadata | Width/Height Presence | Non-null width & height | 100% | Server query |
| Performance | Avg Photo Upload Time | Mean duration (ms) | < 600ms | UploadLogger COMPLETE entries |
| Performance | Video Processing Time | Server-side processing duration | Baseline + monitor drift | Server logs (needs field) |
| Memory | Peak RSS During Upload | Max RSS mark delta | - (baseline first) | MemoryProfiler marks |
| Resume (Phase E) | Resume Success Rate | Resumed tasks / attempted resumes | > 90% | Snapshot + log events |
| Concurrency | Throughput Gain | Time saved vs sequential | > 30% improvement for N>=3 | A/B timing capture |

## 3. Log Extraction Script (Pseudo)
```bash
# Filter PROGRESS milestones & completion
grep "[UploadFlow]" app.log | awk '/COMPLETE/ { ... }'
```
(Will implement proper Dart / Node script in future iteration.)

## 4. Daily Checklist
- [ ] Any video failures? (If yes, capture sample log & status code)
- [ ] Ratio population < target? Investigate specific indices
- [ ] Unexpected 401 refresh retries spike? (>5 per 100 tasks)
- [ ] Peak memory > baseline +20%? (Check large posts only)
- [ ] Duplicate photo detection? (Manual scan for same UUID twice per post)

## 5. Alert Thresholds (Manual Stage)
| Metric | Warning | Critical |
|--------|---------|----------|
| Photo Success Rate | <97% | <95% |
| Video Success Rate | <93% | <90% |
| Ratio Population | <93% | <88% |
| Avg Photo Upload Time | >700ms | >1000ms |
| Peak RSS (10 photos) | >Baseline+25% | >Baseline+40% |

## 6. Data Collection Process
1. Enable verbose logging build (debug mode) for sample session.
2. Perform scripted upload set: 1 video + 5 photos.
3. Capture log output to file.
4. Run extraction snippet (future script) to compute metrics.
5. Update baseline table in this document.

## 7. Baseline Table (To Fill)
| Metric | Baseline | Date |
|--------|----------|------|
| Avg Photo Upload Time | TBD | - |
| Photo Success Rate | TBD | - |
| Video Success Rate | TBD | - |
| Ratio Population | TBD | - |
| Peak RSS (3 photo set) | 4.1MB delta | 2025-11-03 |
| Throughput (3 photos concurrent) | TBD | - |

## 8. Implementation Backlog (Monitoring Enhancements)
- [ ] Add structured JSON log option (toggle)
- [ ] Add server field for video processing ms
- [ ] Add automated Dart script to parse logs & emit metrics summary
- [ ] Persist last 5 snapshot upgrade results (Phase E)
- [ ] Add warning banner in debug UI if ratio population dips

## 9. Ownership
| Area | Owner |
|------|-------|
| Client Metrics Extraction | Frontend Engineer |
| Server Logs Aggregation | Backend Engineer |
| Memory Baselines | Performance Engineer |
| Phase E Resume Metrics | Feature Owner |

## 10. Next Steps
- [ ] Approve checklist
- [ ] Capture initial baseline batch
- [ ] Implement basic parsing script
- [ ] Decide on alerting path (manual vs channel notifications)

---
END
