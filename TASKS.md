# AI Agent Task Backlog

> **Purpose:** Bite-sized tasks that AI agents can pick up and complete independently  
> **Last Updated:** November 22, 2025

This document breaks down roadmap features into small, independent tasks that can be completed by AI agents in 1-4 hours each.

---

## 📋 How to Use This Document

### For AI Agents
1. **Pick a task** from the "Ready" section
2. **Update status** to "In Progress" with your name
3. **Complete the task** following the acceptance criteria
4. **Move to "Done"** when merged to main
5. **Update ROADMAP_TRACKING.md** to check off the parent task

### Task Sizing
- 🟢 **Small (1-2 hours)** - Single file changes, CSS updates, simple logic
- 🟡 **Medium (2-4 hours)** - Multiple file changes, new components, moderate complexity
- 🔴 **Large (4+ hours)** - Should be broken down further

### Task Format
```markdown
**[Feature Name] - Task Title** 🟢
- **Description:** What needs to be done
- **Files:** Which files to modify
- **Acceptance Criteria:** How to verify it's complete
- **Dependencies:** What must be done first (if any)
- **Status:** Ready / In Progress / Done
```

---

## 🚀 Quick Wins (< 2 hours each)

### ✅ Ready to Start

**[UI] Add Search/Filter Bar** 🟢
- **Description:** Add a search bar to filter teams/fans in the standings table
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - Search box appears above standings table
  - Filters teams by name or fan name as user types
  - Works on mobile (responsive)
  - No JavaScript errors in console
- **Dependencies:** None
- **Status:** Ready

**[UI] Add Keyboard Shortcuts** 🟢
- **Description:** Implement keyboard shortcuts for navigation (? for help, t for trends, etc.)
- **Files:** `lib/standings.html.erb`
- **Acceptance Criteria:**
  - Press `?` to show keyboard shortcuts modal
  - Press `l` to go to League tab
  - Press `m` to go to Matchups tab
  - Press `s` to go to Standings tab
  - Press `t` to go to Trends tab
  - Press `Esc` to close modals
  - Works without conflicting with browser shortcuts
- **Dependencies:** None
- **Status:** Ready

**[UI] Improve Loading States** 🟢
- **Description:** Add skeleton screens for loading charts and data
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - Skeleton screens show while data loads
  - Smooth transition from skeleton to content
  - Matches site's design aesthetic
  - Works for all tabs
- **Dependencies:** None
- **Status:** Ready

**[UI] Add Print Stylesheet** 🟢
- **Description:** Create print-friendly version of standings
- **Files:** `lib/styles.css`
- **Acceptance Criteria:**
  - Print layout is clean and readable
  - Hides navigation and decorative elements
  - Fits on standard letter/A4 paper
  - Shows all important standings info
  - Test with Chrome and Firefox print preview
- **Dependencies:** None
- **Status:** Ready

**[Meta] Add Social Share Cards** 🟢
- **Description:** Add Open Graph and Twitter Card meta tags for better link previews
- **Files:** `lib/standings.html.erb`
- **Acceptance Criteria:**
  - og:title, og:description, og:image tags added
  - twitter:card, twitter:title, twitter:description tags added
  - Use favicon or create simple og:image
  - Test with Facebook Debugger and Twitter Card Validator
- **Dependencies:** None
- **Status:** Ready

**[UI] Add Mobile Bottom Navigation** 🟢
- **Description:** Add a fixed bottom nav bar for mobile devices (< 768px)
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - Bottom nav shows on mobile only
  - Icons for League, Matchups, Standings, Trends
  - Active tab highlighted
  - Doesn't overlap content
  - Smooth transitions
- **Dependencies:** None
- **Status:** Ready

**[Data] Add Color-Coded Streaks** 🟢
- **Description:** Color code win/loss streaks in standings (green for W, red for L)
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - W streaks show in green
  - L streaks show in red
  - OT streaks show in orange
  - Maintains accessibility (WCAG AA contrast)
  - Works in dark mode
- **Dependencies:** None
- **Status:** Ready

---

## 📈 P0 Feature: Enhanced Trend Charts

### ✅ Ready to Start

**[Charts] Enhance StandingsHistoryTracker to Store Additional Stats** 🟡
- **Description:** Modify tracker to store W/L/OTL, goals for/against, games played
- **Files:** `lib/standings_history_tracker.rb`, `spec/standings_history_tracker_spec.rb`
- **Acceptance Criteria:**
  - `standings_history.json` includes new fields in `details` object
  - Existing functionality still works
  - Tests pass
  - Backward compatible (handles old data format)
  - Run `ruby update_standings.rb` to verify
- **Dependencies:** None
- **Status:** Ready

**[Charts] Add Win/Loss Distribution Chart** 🟡
- **Description:** Create stacked bar chart showing W/L/OTL for each fan
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - Chart displays in Trends tab
  - Uses Chart.js with stacked bars
  - Shows Wins (green), Losses (red), OT Losses (orange)
  - Responsive on mobile
  - Has loading and error states
  - Matches site color scheme
- **Dependencies:** Enhanced StandingsHistoryTracker
- **Status:** Ready

**[Charts] Add Goal Differential Trend Chart** 🟡
- **Description:** Create line chart showing goal differential over time per fan
- **Files:** `lib/standings.html.erb`
- **Acceptance Criteria:**
  - Chart displays in Trends tab
  - Uses Chart.js line chart
  - One line per fan (team colors)
  - X-axis: dates, Y-axis: goal differential
  - Tooltips show date and value
  - Responsive on mobile
- **Dependencies:** Enhanced StandingsHistoryTracker
- **Status:** Ready

**[Charts] Add Points Per Game Efficiency Chart** 🟡
- **Description:** Create line chart showing points earned per game over time
- **Files:** `lib/standings.html.erb`
- **Acceptance Criteria:**
  - Chart displays in Trends tab
  - Shows points/game efficiency metric
  - One line per fan
  - Highlights most efficient teams
  - Responsive on mobile
- **Dependencies:** Enhanced StandingsHistoryTracker
- **Status:** Ready

**[Charts] Add Division Rankings Over Time Chart** 🟡
- **Description:** Create animated line chart showing division rank changes
- **Files:** `lib/standings.html.erb`
- **Acceptance Criteria:**
  - Chart displays in Trends tab
  - Shows division rank (1st, 2nd, 3rd, etc.)
  - Y-axis inverted (1st place at top)
  - One line per fan
  - Responsive on mobile
- **Dependencies:** Enhanced StandingsHistoryTracker (with division rank)
- **Status:** Ready

**[Charts] Add Chart Export Functionality** 🟢
- **Description:** Add "Export as PNG" button to each chart
- **Files:** `lib/standings.html.erb`
- **Acceptance Criteria:**
  - Button appears on each chart
  - Clicking downloads chart as PNG image
  - Filename includes chart name and date
  - Works in Chrome, Firefox, Safari
- **Dependencies:** At least one new chart implemented
- **Status:** Ready

---

## 🎯 P0 Feature: Game Predictions System

### ✅ Ready to Start

**[Predictions] Create PredictionTracker Class** 🟡
- **Description:** Create Ruby class to manage prediction storage and retrieval
- **Files:** `lib/prediction_tracker.rb`, `spec/prediction_tracker_spec.rb`
- **Acceptance Criteria:**
  - `store_prediction(fan_name, game_id, predicted_winner)` method
  - `get_predictions(game_id)` method
  - `calculate_accuracy(fan_name)` method
  - Stores in `data/predictions.json`
  - Tests pass with 100% coverage
  - Handles edge cases (duplicate predictions, invalid data)
- **Dependencies:** None
- **Status:** Ready

**[Predictions] Create PredictionProcessor Class** 🟡
- **Description:** Create class to process game results and update prediction accuracy
- **Files:** `lib/prediction_processor.rb`, `spec/prediction_processor_spec.rb`
- **Acceptance Criteria:**
  - `process_completed_game(game_id, winner)` method
  - Updates prediction records with correct/incorrect
  - Calculates running accuracy percentages
  - Tests pass with 100% coverage
  - Handles games with no predictions
- **Dependencies:** PredictionTracker created
- **Status:** Ready

**[Predictions] Add Voting UI to Featured Matchup** 🟡
- **Description:** Add vote buttons to the featured matchup card
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - Two vote buttons (one per team) appear
  - Buttons disabled after voting
  - Vote count shows total votes per team
  - Voting deadline shown (e.g., "Vote before 7:00 PM")
  - Mobile responsive
  - Accessible (ARIA labels, keyboard navigation)
- **Dependencies:** PredictionTracker created
- **Status:** Ready

**[Predictions] Create Prediction Leaderboard** 🟢
- **Description:** Add a leaderboard showing prediction accuracy for all fans
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - Displays in League tab or new Predictions tab
  - Shows fan name, total predictions, correct predictions, accuracy %
  - Sorted by accuracy (ties broken by total predictions)
  - Shows badges for top predictors
  - Updates after each game
- **Dependencies:** PredictionProcessor created
- **Status:** Ready

**[Predictions] Add GitHub Action for Prediction Processing** 🟡
- **Description:** Create workflow to process predictions after games complete
- **Files:** `.github/workflows/process-predictions.yml`
- **Acceptance Criteria:**
  - Runs every hour during season
  - Fetches completed games from NHL API
  - Processes predictions via PredictionProcessor
  - Updates predictions.json
  - Commits changes back to repo
  - Handles API errors gracefully
- **Dependencies:** PredictionProcessor created
- **Status:** Ready

---

## ⚡ P0 Feature: Real-Time Score Updates

### ✅ Ready to Start

**[Live] Create LiveGameTracker Class** 🟡
- **Description:** Create Ruby class to fetch live game data from NHL API
- **Files:** `lib/live_game_tracker.rb`, `spec/live_game_tracker_spec.rb`
- **Acceptance Criteria:**
  - `fetch_live_games()` method returns active games
  - `get_game_state(game_id)` returns current score, period, time
  - Handles NHL API rate limits
  - Tests pass with mocked API responses
  - Error handling for API failures
- **Dependencies:** None
- **Status:** Ready

**[Live] Add JavaScript Live Score Polling** 🟡
- **Description:** Add JavaScript to poll for live scores every 60 seconds
- **Files:** `lib/standings.html.erb`
- **Acceptance Criteria:**
  - Fetches `live_games.json` every 60 seconds
  - Only polls during game windows (e.g., 4 PM - 11 PM PT)
  - Updates scores on page without reload
  - Stops polling when no games active
  - Handles fetch errors gracefully
  - No memory leaks (proper cleanup)
- **Dependencies:** LiveGameTracker created, live_games.json endpoint
- **Status:** Ready

**[Live] Add Live Game Indicators** 🟢
- **Description:** Add visual 🔴 LIVE indicators to games in progress
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - Red "🔴 LIVE" badge shows for active games
  - Appears in matchups tab and standings
  - Pulsing animation for attention
  - Shows current score and period
  - Mobile responsive
- **Dependencies:** Live score polling implemented
- **Status:** Ready

**[Live] Create Live Games JSON Endpoint** 🟢
- **Description:** Add script to generate live_games.json for JavaScript to consume
- **Files:** `update_standings.rb` or new script
- **Acceptance Criteria:**
  - Generates `_site/live_games.json`
  - Contains current scores, period, time remaining
  - Updates every time update script runs
  - Small file size (< 10KB)
  - Valid JSON format
- **Dependencies:** LiveGameTracker created
- **Status:** Ready

**[Live] Add Real-Time Standings Updates** 🟡
- **Description:** Update standings points in real-time as games complete
- **Files:** `lib/standings.html.erb`
- **Acceptance Criteria:**
  - When game ends, points update immediately
  - Smooth animation for point changes
  - Fan rankings update if needed
  - Works with JavaScript polling
  - No full page reload required
- **Dependencies:** Live score polling, standings recalculation logic
- **Status:** Ready

---

## 🔔 P1 Feature: Push Notifications

### ✅ Ready to Start

**[Notifications] Implement Service Worker** 🟡
- **Description:** Create service worker for push notification support
- **Files:** `_site/sw.js` (new), `lib/standings.html.erb`
- **Acceptance Criteria:**
  - Service worker registers successfully
  - Handles push events
  - Shows notifications with proper content
  - Works offline (basic caching)
  - Tests in Chrome and Firefox
- **Dependencies:** None
- **Status:** Ready

**[Notifications] Add Web Push API Integration** 🔴
- **Description:** Integrate Web Push API for sending notifications
- **Files:** Multiple (backend service, subscription management)
- **Acceptance Criteria:**
  - User can subscribe to notifications
  - Subscription stored securely
  - Can send test notification
  - Unsubscribe works
  - Complies with browser permissions
- **Dependencies:** Service worker implemented
- **Status:** Ready (Large - consider breaking down)

**[Notifications] Create Notification Preferences Page** 🟡
- **Description:** Add UI for users to manage notification preferences
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - Page accessible from settings/menu
  - Checkboxes for each notification type
  - Game start reminders (1 hour before)
  - Game results
  - Position changes
  - Prediction reminders
  - Save preferences to localStorage
  - Mobile responsive
- **Dependencies:** None (can be built independently)
- **Status:** Ready

---

## 🏒 P1 Feature: Player Statistics

### ✅ Ready to Start

**[Players] Create PlayerStatsTracker Class** 🟡
- **Description:** Create class to fetch and store player statistics
- **Files:** `lib/player_stats_tracker.rb`, `spec/player_stats_tracker_spec.rb`
- **Acceptance Criteria:**
  - `fetch_roster(team_id)` returns team roster
  - `fetch_player_stats(player_id)` returns stats
  - `get_team_leaders(team_id)` returns top 3 players
  - Caches data to avoid repeated API calls
  - Tests pass with mocked responses
- **Dependencies:** None
- **Status:** Ready

**[Players] Add Player Stats Modal** 🟡
- **Description:** Create modal to show player stats when team card is clicked
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - Modal opens when "View Players" clicked
  - Shows top 3-5 players with stats
  - Goals, assists, points, +/-
  - Close button and ESC key work
  - Mobile responsive
  - Accessible (ARIA, focus management)
- **Dependencies:** PlayerStatsTracker created
- **Status:** Ready

**[Players] Add Top Performers Section** 🟢
- **Description:** Add section showing league-wide top performers
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - Shows top 5 goal scorers
  - Shows top 5 point leaders
  - Links to team/fan
  - Updates daily
  - Mobile responsive
- **Dependencies:** PlayerStatsTracker created
- **Status:** Ready

---

## 📊 P2 Feature: Advanced Analytics

### ✅ Ready to Start

**[Analytics] Create Power Rankings Algorithm** 🔴
- **Description:** Implement algorithm to calculate power rankings beyond just points
- **Files:** `lib/power_rankings.rb`, `spec/power_rankings_spec.rb`
- **Acceptance Criteria:**
  - Considers recent form (last 10 games)
  - Weights wins against strong opponents
  - Accounts for goal differential
  - Returns ranked list with scores
  - Tests verify algorithm correctness
- **Dependencies:** Historical stats data
- **Status:** Ready (Large - consider breaking down)

**[Analytics] Add Strength of Schedule Display** 🟡
- **Description:** Calculate and display remaining schedule difficulty
- **Files:** `lib/standings.html.erb`, existing analytics classes
- **Acceptance Criteria:**
  - Shows difficulty rating (easy/medium/hard)
  - Considers opponent strength
  - Shows next 5 games with difficulty
  - Updates daily
  - Visual indicators (colors, icons)
- **Dependencies:** Power rankings or team strength metrics
- **Status:** Ready

**[Analytics] Create Playoff Probability Calculator** 🔴
- **Description:** Calculate odds of making playoffs for each team
- **Files:** `lib/playoff_probability.rb`, `spec/playoff_probability_spec.rb`
- **Acceptance Criteria:**
  - Runs Monte Carlo simulations
  - Considers remaining schedule
  - Returns probability percentage
  - Updates daily
  - Shows trend over time
- **Dependencies:** Historical data, schedule
- **Status:** Ready (Large - consider breaking down)

---

## 💡 Documentation & Polish Tasks

### ✅ Ready to Start

**[Docs] Add Inline Code Comments** 🟢
- **Description:** Add JSDoc-style comments to all JavaScript functions
- **Files:** `lib/standings.html.erb`
- **Acceptance Criteria:**
  - Every function has description comment
  - Parameters documented
  - Return values documented
  - Example usage where helpful
- **Dependencies:** None
- **Status:** Ready

**[Docs] Create Architecture Diagram** 🟢
- **Description:** Create visual diagram of system architecture
- **Files:** `ARCHITECTURE.md` (new)
- **Acceptance Criteria:**
  - Shows data flow (NHL API → Ruby → JSON → Browser)
  - Shows GitHub Actions workflows
  - Shows file structure
  - Uses Mermaid or ASCII art
  - Includes explanation of each component
- **Dependencies:** None
- **Status:** Ready

**[Polish] Improve Error Messages** 🟢
- **Description:** Add user-friendly error messages throughout the site
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - Replace generic "Error loading data" with specific messages
  - Add retry buttons where appropriate
  - Show helpful troubleshooting tips
  - Error states are visually clear
  - Accessible (screen reader friendly)
- **Dependencies:** None
- **Status:** Ready

**[Polish] Add Animation and Transitions** 🟢
- **Description:** Add smooth transitions and micro-animations throughout
- **Files:** `lib/styles.css`
- **Acceptance Criteria:**
  - Tab switches have smooth transitions
  - Card expansions animate smoothly
  - Hover states have subtle effects
  - Loading spinners are smooth
  - No janky animations (60fps target)
  - Respects prefers-reduced-motion
- **Dependencies:** None
- **Status:** Ready

**[A11y] Accessibility Audit and Fixes** 🟡
- **Description:** Run accessibility audit and fix all WCAG AA issues
- **Files:** `lib/standings.html.erb`, `lib/styles.css`
- **Acceptance Criteria:**
  - Run axe or Lighthouse accessibility scan
  - Fix all critical and serious issues
  - Add missing ARIA labels
  - Improve keyboard navigation
  - Ensure color contrast meets WCAG AA
  - Test with screen reader
- **Dependencies:** None
- **Status:** Ready

---

## 🔄 Continuous Tasks (Can Always Be Done)

**[Tests] Add More Test Coverage** 🟢
- **Description:** Increase test coverage for existing code
- **Files:** `spec/*_spec.rb`
- **Acceptance Criteria:**
  - Pick any file with < 90% coverage
  - Add tests for uncovered branches
  - Tests are meaningful (not just coverage)
  - All tests pass
- **Dependencies:** None
- **Status:** Always Ready

**[Refactor] Code Quality Improvements** 🟢
- **Description:** Refactor any code that has technical debt
- **Files:** Any Ruby files in `lib/`
- **Acceptance Criteria:**
  - Identify code smell or duplication
  - Refactor to improve readability/maintainability
  - Add tests if missing
  - All existing tests still pass
  - Rubocop violations fixed
- **Dependencies:** None
- **Status:** Always Ready

**[Performance] Performance Optimization** 🟡
- **Description:** Optimize slow parts of the application
- **Files:** Various
- **Acceptance Criteria:**
  - Identify performance bottleneck
  - Implement optimization
  - Measure improvement (before/after)
  - Document the change
  - All functionality still works
- **Dependencies:** None
- **Status:** Always Ready

---

## 📌 Dependency Chain Visualization

```
Enhanced Charts:
  └─► Enhance StandingsHistoryTracker (do first)
      ├─► Win/Loss Chart
      ├─► Goal Diff Chart
      ├─► PPG Chart
      └─► Division Rank Chart
          └─► Chart Export Feature

Predictions:
  ├─► PredictionTracker Class (do first)
  │   ├─► PredictionProcessor Class
  │   │   └─► GitHub Action
  │   └─► Voting UI
  └─► Prediction Leaderboard

Real-Time:
  ├─► LiveGameTracker Class (do first)
  │   └─► Live Games JSON Endpoint
  ├─► JavaScript Polling
  │   ├─► Live Indicators
  │   └─► Real-Time Updates

Push Notifications:
  └─► Service Worker (do first)
      └─► Web Push Integration
          └─► Preferences Page (can be parallel)

Player Stats:
  └─► PlayerStatsTracker Class (do first)
      ├─► Player Modal
      └─► Top Performers Section
```

---

## 🎯 Recommended Order for AI Agents

### Phase 1: Quick Wins (Week 1)
Start with any task marked 🟢 from "Quick Wins" - these are independent and provide immediate value.

### Phase 2: Enhanced Charts Foundation (Week 2)
1. Enhance StandingsHistoryTracker
2. Win/Loss Distribution Chart
3. Goal Differential Chart
4. Other charts in parallel

### Phase 3: Predictions System (Weeks 3-4)
1. PredictionTracker Class
2. PredictionProcessor Class
3. Voting UI
4. Leaderboard
5. GitHub Action

### Phase 4: Real-Time Updates (Weeks 5-6)
1. LiveGameTracker Class
2. Live Games JSON Endpoint
3. JavaScript Polling
4. Live Indicators
5. Real-Time Standings Updates

### Phase 5: Continue with P1/P2 Features
Follow dependency chains shown above.

---

## 💡 Tips for AI Agents

1. **Always check dependencies first** - Don't start a task if its dependencies aren't complete
2. **Update status immediately** - Mark "In Progress" when you start
3. **Write tests first** - For backend tasks, write tests before implementation
4. **Test on mobile** - Most users are on phones, always test responsive design
5. **Run linters** - Fix Rubocop violations before committing
6. **Keep PRs small** - One task per PR makes review easier
7. **Update tracking docs** - Check off items in ROADMAP_TRACKING.md when done
8. **Document as you go** - Add comments and update docs
9. **Consider accessibility** - Always think about keyboard users and screen readers
10. **Celebrate wins** - Move to "Done" and be proud of your work! 🎉

---

## 📊 Backlog Stats

**Total Tasks:** 45+  
**Quick Wins:** 7  
**P0 Tasks:** 16  
**P1 Tasks:** 7  
**P2 Tasks:** 3  
**Polish/Docs:** 6  
**Continuous:** 3+  

**Average Task Size:** 2-3 hours  
**Ready to Start:** All tasks with no dependencies  
**Blocked:** None currently  

---

*Keep this document updated as tasks are completed. Add new bite-sized tasks as features are broken down further.*
