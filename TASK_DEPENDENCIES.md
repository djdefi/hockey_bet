# Task Dependency Diagram

This visual diagram shows how tasks relate to each other and the recommended execution flow.

```
Legend:
🔴 = CRITICAL (blocks other high-impact work)
🟡 = HIGH (directly drives metrics)
🟢 = MEDIUM/LOW (supporting or polish)
→ = depends on
═══ = phase boundary
```

## Full Dependency Map

```
═══════════════════════════════════════════════════════════════════════
PHASE 1: FOUNDATION (Do First - Enables Everything Else)
═══════════════════════════════════════════════════════════════════════

🔴 Task 1: Enhance StandingsHistoryTracker
           (Add W/L/OTL, Goals data)
           │
           ├────→ 🟢 Task 6: Goal Differential Chart
           ├────→ 🟢 Task 7: Win/Loss Trends Chart  
           ├────→ 🟢 Task 8: Division Rankings Chart
           └────→ [Enables all Phase 2]

🔴 Task 2: Create PredictionTracker Class
           (Store/retrieve predictions)
           │
           └────→ 🔴 Task 3: Create PredictionProcessor
                             (Calculate accuracy)
                             │
                             ├────→ 🟡 Task 4: Prediction Voting UI
                             │                  │
                             └──────────────────┴────→ 🟡 Task 5: GitHub Action
                                                                   (Process predictions)

═══════════════════════════════════════════════════════════════════════
PHASE 2: ENHANCED VISUALIZATIONS (Quick Wins)
═══════════════════════════════════════════════════════════════════════

[Task 1] → 🟢 Task 6: Goal Differential Chart ──┐
[Task 1] → 🟢 Task 7: Win/Loss Trends Chart ────┤
[Task 1] → 🟢 Task 8: Division Rankings Chart ──┤
                                                 │
           🟢 Task 9: Interactive Chart Controls ←┘
              (zoom/pan/export)

═══════════════════════════════════════════════════════════════════════
PHASE 3: REAL-TIME ENGAGEMENT (Game Day Features)
═══════════════════════════════════════════════════════════════════════

🟡 Task 10: Create LiveGameTracker Class
            (Poll NHL API for live games)
            │
            └────→ 🟡 Task 11: GitHub Action for Live Updates
                                (5-minute intervals)
                                │
                                └────→ 🟡 Task 12: Live Scores UI
                                                   (Auto-refresh display)
                                                   │
                                                   └────→ 🟢 Task 13: "🔴 LIVE" Indicators
                                                                      (In standings table)

═══════════════════════════════════════════════════════════════════════
PHASE 4: RETENTION FEATURES (Keep Users Coming Back)
═══════════════════════════════════════════════════════════════════════

🟡 Task 14: Web Push Notifications
            (Service worker + permission UI)
            │
            ├────→ 🟡 Task 15: Notification Triggers
            │                  (Game reminders, results)
            │
            └────→ 🟢 Task 16: Weekly Digest
                               (Summary notification)

🟢 Task 17: Achievement Badges
            (Display on League page)
            [Independent - can do anytime after Phase 1]

═══════════════════════════════════════════════════════════════════════
PHASE 5: POLISH & OPTIMIZATION (Performance & UX)
═══════════════════════════════════════════════════════════════════════

🟢 Task 18: Response Caching
            (Reduce API calls)
            [Independent]

🟢 Task 19: Optimize GitHub Actions
            (Smart scheduling, conditional execution)
            [Independent]

🟢 Task 20: PWA Offline Capabilities
            (Service worker caching)
            [Can enhance Task 14's service worker]

```

## Critical Path Analysis

The **Critical Path** (tasks that MUST be done before others can start):

```
Task 1 ──→ Tasks 6,7,8 ──→ Task 9
└─── Enables all Phase 2 visualization work

Task 2 ──→ Task 3 ──→ Task 4 ──→ Task 5
└─── Enables complete predictions feature

Task 10 ──→ Task 11 ──→ Task 12 ──→ Task 13
└─── Enables complete live scoring feature

Task 14 ──→ Tasks 15,16
└─── Enables notification features
```

## Parallel Work Opportunities

These tasks can be done simultaneously (no dependencies):

### Option A: Two AI Agents Working in Parallel

**Agent 1: Predictions Track**
```
Week 1-2: Tasks 2, 3 (Foundation)
Week 2-3: Tasks 4, 5 (UI + Automation)
```

**Agent 2: Visualizations Track**
```
Week 1: Task 1 (Data enhancement)
Week 2-3: Tasks 6, 7, 8, 9 (All charts)
```

**Result:** Both Phase 1 and Phase 2 complete in 3 weeks instead of 5 weeks

### Option B: Three AI Agents Working in Parallel

**Agent 1:** Tasks 1, 6, 7, 8, 9 (Visualizations)  
**Agent 2:** Tasks 2, 3, 4, 5 (Predictions)  
**Agent 3:** Tasks 10, 11, 12, 13 (Live Scores)

**Result:** Phases 1-3 complete in 3-4 weeks instead of 8 weeks

## Priority Decision Tree

```
START HERE
│
├─ "I want MAXIMUM engagement increase"
│  └─→ Do: Phase 1 (Predictions) first
│     Impact: 2-3x daily active users
│
├─ "I want QUICK WINS that look impressive"
│  └─→ Do: Task 1 → Phase 2 (Charts) first
│     Impact: 4 new charts, very visual
│
├─ "I want GAME DAY traffic"
│  └─→ Do: Phase 3 (Live Scores) first
│     Impact: Real-time scores create urgency
│
├─ "I have LIMITED TIME (1 week)"
│  └─→ Do: Just Task 1 + Tasks 6,7,8
│     Impact: Enhanced data + 3 new charts
│
└─ "I want LONG-TERM retention"
   └─→ Do: Phase 1 → Phase 4 (Predictions + Notifications)
      Impact: Daily habits + push reminders
```

## Resource Planning

### Single Developer Timeline
```
Week 1-3:   Phase 1 (Predictions)         [13-18h]
Week 4-5:   Phase 2 (Charts)              [8-12h]
Week 6-8:   Phase 3 (Live Scores)         [10-14h]
Week 9-11:  Phase 4 (Notifications)       [11-15h]
Week 12:    Phase 5 (Polish)              [6-9h]
────────────────────────────────────────────────
Total:      12 weeks                       [48-68h]
```

### Two Developers Timeline (Parallel Work)
```
Week 1-3:   Phase 1 + Phase 2 (parallel) [21-30h split]
Week 4-6:   Phase 3 + Phase 4 (parallel) [21-29h split]
Week 7:     Phase 5 (one dev)            [6-9h]
────────────────────────────────────────────────
Total:      7 weeks                       [48-68h total]
```

### Three Developers Timeline (Maximum Parallel)
```
Week 1-3:   Phases 1, 2, 3 (all parallel) [31-44h split]
Week 4-5:   Phase 4 (two devs)            [11-15h split]
Week 6:     Phase 5 (one dev)             [6-9h]
────────────────────────────────────────────────
Total:      6 weeks                        [48-68h total]
```

## Impact vs Effort Matrix

```
HIGH IMPACT ↑
            │
            │  P1: Predictions    P3: Live Scores
            │  (Tasks 1-5)        (Tasks 10-13)
            │    13-18h              10-14h
            │      🔥🔥🔥               🔥🔥
            │
IMPACT      │  
            │  P4: Notifications  P2: Charts
            │  (Tasks 14-17)      (Tasks 6-9)
            │    11-15h             8-12h
            │      🔥                 🔥🔥
            │
            │                     P5: Polish
            │                     (Tasks 18-20)
            │                       6-9h
            │                        ⭐
LOW IMPACT  └────────────────────────────────→ HIGH EFFORT
            LOW EFFORT

Best ROI: Phase 2 (Charts) - Low effort, high visibility
Highest Impact: Phase 1 (Predictions) - Primary engagement driver
```

## Success Milestones

```
Milestone 1: Phase 1 Complete
├─ Predictions working
├─ Leaderboard showing
└─ 📊 KPI: 8-10 fans making predictions daily

Milestone 2: Phases 1+2 Complete  
├─ 4 new interactive charts
├─ Better data storytelling
└─ 📊 KPI: Time on site +30%

Milestone 3: Phases 1+2+3 Complete
├─ Real-time live scores
├─ "🔴 LIVE" indicators
└─ 📊 KPI: 10+ fans active during games

Milestone 4: Phases 1-4 Complete
├─ Push notifications working
├─ Achievement badges live
└─ 📊 KPI: 60%+ daily return rate

Milestone 5: All Phases Complete
├─ Optimized and polished
├─ Offline support
└─ 📊 KPI: 70% DAU, 6-8 min time on site
```

## Risk Mitigation

### High-Risk Dependencies

**Risk:** Task 1 blocks all of Phase 2  
**Mitigation:** Do Task 1 first, test thoroughly before starting Phase 2

**Risk:** Task 2 blocks entire predictions feature  
**Mitigation:** Comprehensive testing, consider mock data for UI development

**Risk:** GitHub Actions rate limits for live scores  
**Mitigation:** 
- Start with 15-minute intervals
- Upgrade to GitHub Pro ($4/mo) if needed
- Cache aggressively

**Risk:** Browser notification permissions denied  
**Mitigation:**
- Make feature optional
- Explain benefits clearly
- Provide fallback (in-app notifications)

### Low-Risk, High-Value Alternatives

If any task is blocked or too complex:

**Instead of Task 10-13 (Live Scores):**
→ Focus on Task 6-9 (Charts) - same time investment, lower risk

**Instead of Task 14-16 (Push Notifications):**
→ Do Task 17 (Achievements) - simpler, still drives retention

**Instead of Phase 5 (Polish):**
→ Double down on Phase 1 enhancements - add more prediction types

---

## Summary: Recommended Execution

For **maximum impact with minimum risk:**

```
✅ WEEK 1-3: Phase 1 (Tasks 1-5)
   Do this first - highest ROI, enables other work

✅ WEEK 4-5: Phase 2 (Tasks 6-9)  
   Quick wins, builds on Task 1, very visual

✅ WEEK 6-8: Phase 3 (Tasks 10-13)
   Game-day features, test during actual games

✅ WEEK 9-11: Phase 4 (Tasks 14-17)
   Retention features, measure impact of Phases 1-3

✅ WEEK 12: Phase 5 (Tasks 18-20)
   Polish and optimize based on real usage data
```

**Total: 12 weeks to transform from passive tracker → active engagement platform**

---

**See [NEXT_TASKS.md](NEXT_TASKS.md) for complete implementation details**  
**See [TASK_SUMMARY.md](TASK_SUMMARY.md) for quick reference**
