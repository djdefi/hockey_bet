# Task Summary: Next 10-20 Priorities

> **Quick Reference:** One-page overview of strategic priorities  
> **For Details:** See [NEXT_TASKS.md](NEXT_TASKS.md) for complete implementation guides

---

## 🎯 The Big Picture

**Goal:** Transform from passive stats tracker → active daily engagement platform  
**Target:** Increase daily active users from 25% (3-4 fans) to 70% (9-10 fans)  
**Method:** Add predictions, live scores, better charts, and notifications  
**Timeline:** 8-12 weeks for all 20 tasks  
**Cost:** $0/month (or $4/month for faster updates)

---

## 📋 Task List (Quick View)

### 🔥 Phase 1: Foundation (CRITICAL - Do First)
These enable the prediction feature, which drives 2-3x increase in daily users.

| # | Task | Time | Blocks |
|---|------|------|--------|
| 1 | Enhance StandingsHistoryTracker (add W/L/Goals data) | 2-3h | Tasks 6-9 |
| 2 | Create PredictionTracker class (store/retrieve predictions) | 3-4h | Tasks 3-5 |
| 3 | Create PredictionProcessor class (calculate accuracy) | 3-4h | Task 5 |
| 4 | Build prediction voting UI (dropdown + submit form) | 3-4h | Task 5 |
| 5 | Add GitHub Action to process predictions | 2-3h | - |

**Phase 1 Total:** 13-18 hours  
**Impact:** 🔥🔥🔥 (Primary engagement driver)

---

### 📊 Phase 2: Enhanced Visualizations
Better charts increase time on site by ~30%.

| # | Task | Time | Depends On |
|---|------|------|------------|
| 6 | Create Goal Differential chart | 2-3h | Task 1 |
| 7 | Create Win/Loss Trends chart | 2-3h | Task 1 |
| 8 | Create Division Rankings chart | 2-3h | Task 1 |
| 9 | Add interactive controls (zoom/export) | 2-3h | - |

**Phase 2 Total:** 8-12 hours  
**Impact:** 🔥🔥 (Increases time on site)

---

### ⚡ Phase 3: Real-Time Engagement
Live scores create "appointment viewing" during games.

| # | Task | Time | Depends On |
|---|------|------|------------|
| 10 | Create LiveGameTracker class | 3-4h | - |
| 11 | Add GitHub Action for live updates | 2-3h | Task 10 |
| 12 | Build live scores UI with auto-refresh | 3-4h | Task 11 |
| 13 | Add "🔴 LIVE" indicators to tables | 2-3h | Task 12 |

**Phase 3 Total:** 10-14 hours  
**Impact:** 🔥🔥 (Game-day engagement)

---

### 🔔 Phase 4: Retention Features
Notifications and achievements keep users coming back daily.

| # | Task | Time | Depends On |
|---|------|------|------------|
| 14 | Implement web push notifications | 4-5h | - |
| 15 | Add notification triggers (game reminders, results) | 3-4h | Task 14 |
| 16 | Create weekly digest notification | 2-3h | Task 14 |
| 17 | Add achievement badges to League page | 2-3h | - |

**Phase 4 Total:** 11-15 hours  
**Impact:** 🔥 (Daily return rate)

---

### 🎯 Phase 5: Polish & Optimization
Performance improvements and offline support.

| # | Task | Time | Depends On |
|---|------|------|------------|
| 18 | Add response caching for NHL API | 2-3h | - |
| 19 | Optimize GitHub Actions runtime | 2-3h | - |
| 20 | Add PWA offline capabilities | 2-3h | - |

**Phase 5 Total:** 6-9 hours  
**Impact:** ⭐ (Performance/UX polish)

---

## 🚀 Execution Strategy

### Recommended Order

**Sprint 1 (Weeks 1-3): Game Predictions** ← START HERE  
Complete Tasks 1-5. Biggest bang for buck.  
✅ Result: Daily active users increase 2-3x

**Sprint 2 (Weeks 4-5): Enhanced Charts**  
Complete Tasks 6-9. Quick wins.  
✅ Result: Time on site +30%

**Sprint 3 (Weeks 6-8): Real-Time Features**  
Complete Tasks 10-13. Game-day excitement.  
✅ Result: 10+ fans active during games

**Sprint 4 (Weeks 9-11): Retention**  
Complete Tasks 14-17. Keep them coming back.  
✅ Result: 60%+ daily return rate

**Sprint 5 (Week 12): Polish**  
Complete Tasks 18-20. Final touches.  
✅ Result: Fast, reliable, offline-capable

---

## 📊 Success Metrics

### Current State (Baseline)
- **DAU:** 3-4 of 13 fans (25-30%)
- **Time on Site:** ~2 minutes
- **Return Rate:** Weekly
- **Interactive Features:** 0

### Target State (After All Tasks)
- **DAU:** 9-10 of 13 fans (70%+)
- **Time on Site:** 6-8 minutes (+300%)
- **Return Rate:** Daily
- **Interactive Features:** 5+ (predictions, live scores, charts, notifications, achievements)

---

## 🔧 Technical Notes

### Infrastructure
- ✅ All features use existing GitHub Pages + Actions
- ✅ NO replatforming, databases, or user authentication
- ✅ Honor system with 13 hardcoded fan names
- ✅ Data stored in JSON files (`predictions.json`, `live_games.json`, etc.)

### Dependencies
```
Phase 1 → Phase 2 (Task 1 enables Tasks 6-9)
Phase 1 → Phase 3 (Predictions integrate with live scores)
Phase 3 → Phase 4 (Notifications need content from predictions/scores)
All Phases → Phase 5 (Optimization after features exist)
```

### Cost Analysis
- **Free Tier:** 3-hour update intervals (adequate for most)
- **GitHub Pro ($4/mo):** 5-minute updates during games (better for live features)
- **Recommendation:** Start free, upgrade if Phase 3 demands it

---

## 💡 Quick Decision Guide

### "I have 1 week. What should I do?"
**→ Phase 1 (Tasks 1-5):** Game predictions. Highest impact.

### "I have 2 weeks. What should I do?"
**→ Phase 1 + Phase 2 (Tasks 1-9):** Predictions + charts. Two major features.

### "I have 1 month. What should I do?"
**→ Phase 1 + 2 + 3 (Tasks 1-13):** Predictions + charts + live scores. Complete transformation.

### "I want maximum engagement. What's the priority?"
**→ Phase 1 first (predictions), then Phase 4 (notifications).** Daily habit formation.

### "I want quick wins. What's the priority?"
**→ Phase 2 (enhanced charts).** Low effort, visible impact, builds on existing data.

### "I want game-day traffic. What's the priority?"
**→ Phase 3 (real-time features).** Creates urgency and appointment viewing.

---

## 📁 Related Files

- **[NEXT_TASKS.md](NEXT_TASKS.md)** - Complete implementation guide with code examples (THIS DOCUMENT IS COMPREHENSIVE)
- **[ROADMAP.md (PR #193)](https://github.com/djdefi/hockey_bet/pull/193)** - Original roadmap with full context
- **[INFRASTRUCTURE.md (PR #193)](https://github.com/djdefi/hockey_bet/blob/copilot/create-roadmap-for-improvements/INFRASTRUCTURE.md)** - How features work with GitHub Pages
- **[ROADMAP_CONTEXT.md (PR #193)](https://github.com/djdefi/hockey_bet/blob/copilot/create-roadmap-for-improvements/ROADMAP_CONTEXT.md)** - Target audience and methodology

---

## ✅ Next Steps

1. **Review this summary** and [NEXT_TASKS.md](NEXT_TASKS.md) for details
2. **Choose your sprint** based on timeline and priorities
3. **Start with Phase 1, Task 1** (StandingsHistoryTracker enhancement)
4. **Follow implementation guides** in NEXT_TASKS.md exactly
5. **Test thoroughly** after each task
6. **Track progress** using the checklist in the PR

---

**Questions?** See full implementation details in [NEXT_TASKS.md](NEXT_TASKS.md)  
**Ready to start?** Begin with Task 1: Enhance StandingsHistoryTracker

**Last Updated:** December 21, 2025  
**Total Estimated Effort:** 48-68 hours across all 20 tasks  
**Expected Timeline:** 8-12 weeks for complete implementation
