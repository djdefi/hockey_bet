# AI Agent Task Backlog - HIGH IMPACT FOCUS

> **Purpose:** High-impact tasks that AI agents can pick up to deliver maximum value  
> **Last Updated:** November 22, 2025  
> **Focus:** P0 features that drive 3x DAU, 5x engagement during games

This document focuses on **high-impact tasks** that directly contribute to the roadmap's success metrics.

---

## 🎯 Impact-Driven Prioritization

### What Makes a Task High Impact?
✅ **Directly increases engagement** (DAU, time on site, return rate)  
✅ **Enables P0 features** (predictions, real-time, enhanced charts)  
✅ **Creates user retention** (notifications, daily habits)  
✅ **Provides competitive advantage** (unique features)

### What We're De-prioritizing
❌ **Nice-to-have polish** without measurable impact  
❌ **Developer convenience** that doesn't affect users  
❌ **Features users didn't ask for**  
❌ **Incremental improvements** to existing features

---

## 📋 How to Use This Document

### For AI Agents
1. **Start with CRITICAL PATH** tasks - these unlock everything else
2. **Pick P0 High-Impact tasks** - directly drive engagement metrics
3. **Avoid "Maybe Later" section** unless P0 work is blocked
4. **Update status** and **move to "Done"** when complete

### Task Sizing
- 🔴 **Critical (2-4 hours)** - Blocks other high-impact work
- 🟡 **High Impact (2-4 hours)** - Directly drives metrics
- 🟢 **Supporting (1-2 hours)** - Enables high-impact work

---

## 🔥 CRITICAL PATH - Do These First

These tasks unblock everything else. **Start here.**

### Enhanced Charts Foundation

**[CRITICAL] Enhance StandingsHistoryTracker to Store Additional Stats** 🔴
- **Why Critical:** Blocks all 4 new chart visualizations
- **Impact:** Enables +30% time on site through better data viz
- **Description:** Modify tracker to store W/L/OTL, goals for/against, games played in `details` object
- **Files:** `lib/standings_history_tracker.rb`, `spec/standings_history_tracker_spec.rb`
- **Acceptance Criteria:**
  - `standings_history.json` includes new fields: `wins`, `losses`, `ot_losses`, `goals_for`, `goals_against`, `goal_diff`, `games_played`
  - Backward compatible (handles old data format)
  - All tests pass
  - Run `ruby update_standings.rb` successfully
- **Dependencies:** None
- **Status:** Ready
- **Estimated Value:** Unlocks 4 charts = 6-8 hours of additional work

---

### Game Predictions Foundation

**[CRITICAL] Create PredictionTracker Class** 🔴
- **Why Critical:** Blocks entire prediction voting system
- **Impact:** Enables +300% DAU through daily engagement
- **Description:** Create Ruby class to manage prediction storage and retrieval
- **Files:** `lib/prediction_tracker.rb`, `spec/prediction_tracker_spec.rb`
- **Acceptance Criteria:**
  - `store_prediction(fan_name, game_id, predicted_winner)` method
  - `get_predictions(game_id)` returns all predictions for a game
  - `get_fan_predictions(fan_name)` returns all predictions by a fan
  - Stores in `data/predictions.json` with proper structure
  - Tests pass with 100% coverage
  - Handles edge cases (duplicate predictions, invalid data)
- **Dependencies:** None
- **Status:** Ready
- **Estimated Value:** Unlocks voting UI + leaderboard = 4-6 hours of work

**[CRITICAL] Create PredictionProcessor Class** 🔴
- **Why Critical:** Needed to calculate accuracy and complete prediction loop
- **Impact:** Enables prediction leaderboards and gamification
- **Description:** Create class to process game results and update prediction accuracy
- **Files:** `lib/prediction_processor.rb`, `spec/prediction_processor_spec.rb`
- **Acceptance Criteria:**
  - `process_completed_game(game_id, winner)` updates predictions
  - `calculate_accuracy(fan_name)` returns correct/total and percentage
  - `get_leaderboard()` returns fans sorted by accuracy
  - Tests pass with 100% coverage
  - Handles games with no predictions gracefully
- **Dependencies:** PredictionTracker created
- **Status:** Ready
- **Estimated Value:** Completes prediction feature = high engagement driver

---

### Real-Time Updates Foundation

**[CRITICAL] Create LiveGameTracker Class** 🔴
- **Why Critical:** Blocks entire real-time feature
- **Impact:** Enables +500% engagement during games
- **Description:** Create Ruby class to fetch live game data from NHL API
- **Files:** `lib/live_game_tracker.rb`, `spec/live_game_tracker_spec.rb`
- **Acceptance Criteria:**
  - `fetch_live_games()` returns currently active games
  - `get_game_state(game_id)` returns score, period, time remaining
  - Handles NHL API rate limits properly
  - Caches data appropriately
  - Tests pass with mocked API responses
  - Error handling for API failures
- **Dependencies:** None
- **Status:** Ready
- **Estimated Value:** Unlocks live scores + real-time standings = game-changing feature

---

## ⭐ P0 HIGH-IMPACT TASKS

These directly contribute to engagement metrics. **Do these after Critical Path.**

### Enhanced Charts (Goal: +30% time on site)

**[Charts] Add Goal Differential Trend Chart** 🟡
- **Impact:** HIGH - Shows competitive positioning over time
- **Description:** Create line chart showing goal differential over time per fan
- **Files:** `lib/standings.html.erb`
- **Acceptance Criteria:**
  - Displays in Trends tab below existing chart
  - One line per fan using team colors
  - X-axis: dates, Y-axis: goal differential
  - Tooltips show date and exact value
  - Responsive on mobile
  - Loading and error states
- **Dependencies:** Enhanced StandingsHistoryTracker
- **Status:** Ready
- **Estimated Impact:** Most-requested data visualization

**[Charts] Add Win/Loss Distribution Chart** 🟡
- **Impact:** HIGH - Instant visual of team performance
- **Description:** Create stacked bar chart showing W/L/OTL for each fan
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - Displays in Trends tab
  - Stacked bars: Wins (green), Losses (red), OT Losses (orange)
  - Sorted by total points (like standings)
  - Responsive on mobile
  - Matches site color scheme
- **Dependencies:** Enhanced StandingsHistoryTracker
- **Status:** Ready
- **Estimated Impact:** Quick visual comparison of performance

**[Charts] Add Division Rankings Over Time Chart** 🟡
- **Impact:** MEDIUM - Shows playoff race dynamics
- **Description:** Create line chart showing division rank changes over season
- **Files:** `lib/standings.html.erb`
- **Acceptance Criteria:**
  - Shows division rank (1st, 2nd, 3rd, etc.)
  - Y-axis inverted (1st place at top visually)
  - One line per fan
  - Highlights playoff cutoff line
  - Responsive on mobile
- **Dependencies:** Enhanced StandingsHistoryTracker + division rank tracking
- **Status:** Ready
- **Estimated Impact:** Playoff race excitement

---

### Game Predictions (Goal: +300% DAU)

**[Predictions] Add Voting UI to Featured Matchup** 🟡
- **Impact:** VERY HIGH - Core engagement mechanic
- **Description:** Add vote buttons to the featured matchup card
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - Two vote buttons (one per team)
  - Buttons disabled after voting (localStorage)
  - Vote count shows total votes per team
  - Voting deadline shown (e.g., "Vote closes at 7:00 PM")
  - Mobile responsive
  - Accessible (ARIA labels, keyboard nav)
- **Dependencies:** PredictionTracker created
- **Status:** Ready
- **Estimated Impact:** Creates daily habit of visiting site

**[Predictions] Create Prediction Leaderboard** 🟡
- **Impact:** HIGH - Competitive element drives engagement
- **Description:** Add leaderboard showing prediction accuracy for all fans
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - Shows in League tab or new section
  - Columns: Fan name, predictions made, correct, accuracy %
  - Sorted by accuracy (ties broken by total predictions)
  - Shows badges for top predictors (🥇🥈🥉)
  - Updates after each game
  - Mobile responsive
- **Dependencies:** PredictionProcessor created
- **Status:** Ready
- **Estimated Impact:** Gamification increases return visits

**[Predictions] Add Prediction Reminders** 🟢
- **Impact:** MEDIUM - Increases prediction participation
- **Description:** Show prominent reminder to vote on games starting soon
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - Alert banner when games start in < 2 hours
  - Shows which matchups need predictions
  - Dismissible but reappears for new games
  - Mobile responsive
- **Dependencies:** PredictionTracker, game schedule data
- **Status:** Ready
- **Estimated Impact:** Increases daily active predictions

---

### Real-Time Updates (Goal: +500% engagement during games)

**[Live] Add JavaScript Live Score Polling** 🟡
- **Impact:** VERY HIGH - Real-time engagement during games
- **Description:** Add JavaScript to poll for live scores every 60 seconds
- **Files:** `lib/standings.html.erb`
- **Acceptance Criteria:**
  - Fetches `live_games.json` every 60 seconds
  - Only polls during game windows (4 PM - 11 PM PT)
  - Updates scores without page reload
  - Stops when no games active
  - Handles fetch errors gracefully
  - No memory leaks (proper cleanup on page unload)
- **Dependencies:** LiveGameTracker, live_games.json endpoint
- **Status:** Ready
- **Estimated Impact:** Makes site essential during games

**[Live] Add Live Game Indicators** 🟢
- **Impact:** HIGH - Visual excitement during games
- **Description:** Add visual 🔴 LIVE indicators to active games
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - Red "🔴 LIVE" badge on active games
  - Appears in matchups and standings
  - Pulsing animation
  - Shows current score and period
  - Mobile responsive
- **Dependencies:** Live score polling
- **Status:** Ready
- **Estimated Impact:** Creates urgency and excitement

**[Live] Add Real-Time Standings Updates** 🟡
- **Impact:** VERY HIGH - Points change as games end
- **Description:** Update standings points in real-time as games complete
- **Files:** `lib/standings.html.erb`
- **Acceptance Criteria:**
  - When game ends, points update immediately
  - Smooth animation for changes
  - Rankings recalculate if needed
  - Highlight changed values briefly
  - No full page reload
- **Dependencies:** Live score polling, standings calculation
- **Status:** Ready
- **Estimated Impact:** Creates "can't look away" experience

**[Live] Create Live Games JSON Endpoint** 🟢
- **Impact:** HIGH - Enables all live features
- **Description:** Generate live_games.json for JavaScript consumption
- **Files:** New script or `update_standings.rb`
- **Acceptance Criteria:**
  - Generates `_site/live_games.json`
  - Contains: game_id, teams, scores, period, time, status
  - Updates when script runs
  - File size < 10KB
  - Valid JSON format
- **Dependencies:** LiveGameTracker created
- **Status:** Ready
- **Estimated Impact:** Foundation for real-time features

---

## 💡 SUPPORTING TASKS (Enable High-Impact Work)

These support P0 features but aren't directly user-facing.

**[Backend] Add GitHub Action for Prediction Processing** 🟡
- **Impact:** Enables automated prediction accuracy
- **Description:** Workflow to process predictions after games
- **Files:** `.github/workflows/process-predictions.yml`
- **Acceptance Criteria:**
  - Runs hourly during season
  - Processes completed games
  - Updates predictions.json
  - Commits changes back
  - Error handling
- **Dependencies:** PredictionProcessor
- **Status:** Ready

**[Data] Enhance Bet Stats Calculator for Predictions** 🟢
- **Impact:** Powers prediction accuracy calculations
- **Description:** Extend existing stats to include prediction metrics
- **Files:** `lib/bet_stats_calculator.rb`
- **Acceptance Criteria:**
  - Calculates prediction streaks
  - Tracks accuracy by team
  - Handles edge cases
  - Tests pass
- **Dependencies:** PredictionTracker
- **Status:** Ready

---

## 📌 MAYBE LATER (Low Priority)

These are lower impact. **Only do if P0 work is complete or blocked.**

<details>
<summary>Click to expand low-priority tasks (not recommended for AI agents)</summary>

### UI Polish (No measured impact)

**[UI] Add Search/Filter Bar** 🟢
- Impact: LOW - Users already have Ctrl+F
- Could do if: All P0 tasks complete

**[UI] Add Keyboard Shortcuts** 🟢
- Impact: LOW - Few users will discover/use
- Could do if: All P0 tasks complete

**[UI] Add Print Stylesheet** 🟢
- Impact: VERY LOW - Minimal user request
- Could do if: All P0 tasks complete

**[Meta] Add Social Share Cards** 🟢
- Impact: LOW unless site goes viral
- Could do if: Building viral sharing feature

**[UI] Add Mobile Bottom Navigation** 🟢
- Impact: LOW - Existing nav works fine
- Could do if: Mobile usage data shows problem

**[Data] Add Color-Coded Streaks** 🟢
- Impact: LOW - Incremental polish
- Could do if: All P0 tasks complete

### Documentation (Developer-focused)

**[Docs] Add Inline Code Comments** 🟢
- Impact: NONE on users
- Could do if: Onboarding new developers

**[Docs] Create Architecture Diagram** 🟢
- Impact: NONE on users
- Could do if: Documentation project underway

### Nice-to-Have Features

**[Charts] Add Points Per Game Efficiency Chart** 🟡
- Impact: LOW - Incremental chart
- Could do if: Users request it after other charts

**[Charts] Add Chart Export Functionality** 🟢
- Impact: LOW - No user request for this
- Could do if: Users specifically ask

**[Polish] Improve Error Messages** 🟢
- Impact: LOW - Site rarely errors
- Could do if: Error rate is high

**[Polish] Add Animation and Transitions** 🟢
- Impact: LOW - Polish, not engagement
- Could do if: All P0 complete

**[A11y] Accessibility Audit** 🟡
- Impact: MEDIUM - Important but not urgent
- Could do if: Legal requirement or user request

</details>

---

## 🎯 Recommended Execution Order

### Week 1-2: Critical Path
Focus exclusively on unblocking high-impact work:
1. ✅ Enhance StandingsHistoryTracker (unlocks charts)
2. ✅ Create PredictionTracker (unlocks voting)
3. ✅ Create LiveGameTracker (unlocks real-time)

**Outcome:** All P0 features unblocked

### Week 3-4: High-Impact Features
Build features that drive metrics:
1. ✅ Goal Differential Chart
2. ✅ Win/Loss Distribution Chart
3. ✅ Voting UI
4. ✅ Live Score Polling
5. ✅ Live Indicators

**Outcome:** Users see immediate value

### Week 5-6: Complete P0
Finish the engagement loops:
1. ✅ PredictionProcessor
2. ✅ Prediction Leaderboard
3. ✅ Real-Time Standings Updates
4. ✅ Live Games JSON Endpoint

**Outcome:** All P0 features live, metrics tracking begins

### Week 7+: Measure & Iterate
- Track actual engagement metrics
- Gather user feedback
- Decide on P1 features based on data
- **Do NOT** work on "Maybe Later" tasks without data justification

---

## 📊 Success Metrics

### Track These After P0 Completion

**Baseline (Before):**
- Daily Active Users: _Record_
- Time on Site: _Record_
- Time During Games: _Record_
- Return Rate: _Record_

**Target (After 90 days):**
- Daily Active Users: 3x baseline
- Time on Site: +30% increase
- Time During Games: 5x baseline
- Return Rate: 2x baseline

**How to Measure:**
- Google Analytics or similar
- Track before/after each feature
- User surveys for qualitative feedback

---

## 💡 Key Principles

### For AI Agents
1. **Always ask "What's the impact?"** - If you can't measure it, don't build it
2. **Critical Path first** - Unblock other work before building features
3. **User value over developer convenience** - Polish doesn't drive engagement
4. **Validate with data** - Real metrics, not assumptions
5. **When in doubt, ask** - Get clarity on impact before building

### For Project Managers
1. **Protect against scope creep** - Say no to low-impact work
2. **Measure everything** - Data drives decisions
3. **User feedback trumps assumptions** - Listen to actual users
4. **Kill "nice-to-haves"** - Focus wins every time

---

**Current Stats:**
- Critical Path Tasks: 3 (must do first)
- P0 High-Impact Tasks: 12 (drive metrics)
- Supporting Tasks: 2 (enable P0)
- Maybe Later Tasks: 13 (low priority)

**Focus:** 17 tasks that matter. Ignore the rest unless data says otherwise.

---

*Last updated: November 22, 2025 - Refocused on high-impact work only*
