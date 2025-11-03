# Phase 3.5 QA & Validation Plan

Date: 2025-11-03  
Scope: Validate effectiveness of Phase 3 (bucketing, telemetry, predictive warming) and tune parameters.

---
## 🎯 Objectives
1. Quantify cache hit rate improvement after enabling adjacent prefetch + (optionally) bucketed aspect ratios.
2. Measure average load duration and success rate across typical scroll session.
3. Verify no visual regressions when using bucketed aspect ratios (if adopted for feed tiles).
4. Confirm predictive prefetch reduces perceived latency (few/no placeholder flashes for upcoming items).

---
## 🧪 Test Scenarios
| Scenario | Description | Purpose |
|----------|-------------|---------|
| S1 Baseline Precise Ratio | Scroll ~60 items with precise aspect ratios (bucketing off) | Establish control metrics |
| S2 Bucketing Enabled | Same scroll path with `computeBucketedAspectRatioForWidget` | Measure hit rate delta |
| S3 High Velocity Scroll | Fast flicking through 80+ items | Stress predictive prefetch throttling |
| S4 Slow Scroll / Idle Pauses | Scroll 10 items, pause 3s, repeat | Allow prefetch catch-up & observe telemetry drift |
| S5 Back Navigation Revisit | Scroll 40 items → scroll back to top | Check memory cache retention hit rate |

---
## 🔧 Test Preparation
1. Ensure development build with debug logs enabled.
2. Clear image cache once before first baseline run: `await CachedImageHelper.clearAllCache()`.
3. Reset telemetry at session start: `CachedImageHelper.resetTelemetry()`.
4. (Optional) Disable bucketing by using precise aspect ratio helper.
5. Ensure network is stable (record connection type & approximate latency if possible).

---
## 📊 Metrics to Capture
| Metric | Source | Notes |
|--------|--------|-------|
| cacheHits / cacheMisses | Telemetry | At end of scenario & mid-run snapshot |
| cacheHitRate (%) | Telemetry | Expect uplift with bucketing + prefetch |
| averageLoadTimeMs | Telemetry | Separate for baseline vs bucketing (should not regress >10%) |
| successRate (%) | Telemetry | Should remain ≥98% |
| loadFailures | Telemetry | Investigate if >2 per session |
| Placeholder flashes count (manual) | Visual observation | Lower is better (proxy for warm loads) |
| Subjective latency (cold vs warm item) | Manual | Note any visible difference |

---
## 🧮 Data Collection Template
Paste after each scenario run:
```
Scenario: S# NAME
Duration: (mm:ss)
Items Viewed: ~N
Telemetry JSON: { ... output of CachedImageHelper.getTelemetry().toJson() }
Placeholder Flashes (est): N
Subjective Warm Scroll Quality: (Excellent / Good / Fair / Poor)
Notes: (any anomalies)
```

---
## 📈 Success Criteria
| Criterion | Target | Pass Condition |
|-----------|--------|----------------|
| Hit Rate (S1 Baseline) | Document only | >= 30% expected (due to reuse + memory) |
| Hit Rate (S2 Bucketing) | +10–15 pts vs S1 | e.g., 45%+ overall |
| Avg Load Time (Miss Path) | < 250ms mid device | If >250ms investigate network / size |
| Success Rate | ≥ 98% | Failures < 2% total loads |
| Placeholder Reduction (S2) | Visible decrease | Fewer placeholder flashes vs S1 |
| No Visual Regression | 0 critical issues | No obvious distortion/cropping errors |

---
## 🔍 Investigation Triggers
| Symptom | Action |
|---------|--------|
| Hit rate < target | Confirm prefetch invocation & dedupe set growth; verify scroll index estimation accuracy |
| Avg load time high | Log network responses; check oversized cacheWidth/Height; review DPR assumptions |
| Many failures | Inspect error logs; potential transient network or server 5xx |
| Visual distortion | Ensure bucketing not applied where user expects precise ratio (carousel/detail) |
| Bandwidth spike | Reduce `adjacentCount`; add connectivity check to skip on cellular |

---
## 🛠 Optional Instrumentation Enhancements
- Add a lightweight overlay: top-left text `H:XX% Avg:YYYms Loads: A/B` (dev-only).
- Track number of times `_maybePrefetchAdjacentFeedItems` fires (ensure throttling effective; expect roughly every ~2–3 items advanced).
- Add sampling guard to only process telemetry for 1 in N images if overhead suspected (currently minimal).

---
## 🔄 Tuning Levers
| Lever | Range | Effect |
|-------|-------|-------|
| adjacentCount | 2–5 | Higher improves hit rate until diminishing returns / bandwidth impact |
| bucket adoption scope | feed-only / all list contexts | Wider scope → more reuse, risk subtle layout diffs |
| quality factor (computeTargetCacheDimensions) | 0.9–1.1 | Lower reduces bytes & decode time, may soften sharpness |
| prewarm batch size | 4–8 | Influences initial smoothness vs startup bandwidth |

---
## 🧾 Reporting Format (Final Summary)
```
Phase 3.5 Validation Summary
Device(s): (model, DPR)
Network: (WiFi / cellular, latency ~ ms)
Baseline Hit Rate: X%
Bucketed Hit Rate: Y% (+Δ)
Avg Load Time Miss Path: Baseline A ms / Bucketed B ms (Δ)
Success Rate: Z%
Placeholder Flash Reduction: ~N -> ~M
Conclusions: (proceed / adjust levers / rollback bucketing)
Recommended Defaults: adjacentCount=?, bucketing=ON/OFF, quality=?, prewarmBatch=?
```

---
## ✅ Exit Criteria
All success criteria met OR justified deltas documented with mitigation decisions and recommended defaults locked for production flag rollout.

---
## 📌 Next (Post-Validation)
Proceed to Phase 4 planning ONLY after stable metrics: integrate backend-driven responsive variants (if prioritized) or move to Phase 5 tooling (overlay + CI decode ratio guard).
