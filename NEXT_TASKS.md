# Next 10-20 High-Impact Tasks - Implementation Guide

> **Purpose:** Strategic prioritization of next tasks based on PR #193 roadmap analysis and industry best practices  
> **Last Updated:** December 2025  
> **Focus:** Maximize engagement for 13-person private league  
> **Estimated Total Effort:** 40-60 hours of focused development

---

## 📋 Executive Summary

This document outlines the next 10-20 high-impact tasks to implement following the comprehensive roadmap created in PR #193. Tasks are prioritized based on:

1. **User engagement impact** (DAU, time on site, return rate)
2. **Implementation dependencies** (what unlocks other features)
3. **Effort vs. value ratio** (quick wins vs. long-term payoff)
4. **Industry proven patterns** (features that work in successful fantasy apps)

**Key Constraint:** All features work with existing GitHub Pages + Actions infrastructure. NO user authentication required.

---

## 🎯 Success Metrics

### Current State (Baseline)
- **Daily Active Users:** 3-4 of 13 fans (~25-30%)
- **Time on Site:** ~2 minutes per visit
- **Return Rate:** Weekly check-ins
- **Features:** Static standings, basic chart, upcoming games

### Target State (After Tasks 1-20)
- **Daily Active Users:** 8-10 of 13 fans (~65-75%)
- **Time on Site:** 5-8 minutes per visit
- **Return Rate:** Daily check-ins throughout season
- **Features:** Predictions, live scores, enhanced charts, notifications

**Rationale:** Based on Sleeper/Yahoo Fantasy benchmarks for private leagues. Daily prediction features increase DAU 2-3x. Real-time scores drive game-day engagement.

---

## 🔥 Phase 1: Foundation (Tasks 1-5)
**Goal:** Enable game predictions feature (primary engagement driver)  
**Estimated Time:** 12-16 hours total  
**Impact:** Unlocks ~2-3x increase in daily active users

### Task 1: Enhance StandingsHistoryTracker for Chart Data
**Priority:** 🔴 CRITICAL (blocks Tasks 6-9)  
**Estimated Time:** 2-3 hours  
**Why Critical:** Current tracker only stores points. New charts need W/L/OTL, goals, games played.

**Implementation Details:**
```ruby
# lib/standings_history_tracker.rb
# Modify record_standing method to store additional fields

def record_standing(team_abbrev, timestamp, standing_data)
  # EXISTING: points, division_rank, conference_rank
  # NEW: Add these fields to the details object
  details = {
    points: standing_data[:points],
    division_rank: standing_data[:division_rank],
    conference_rank: standing_data[:conference_rank],
    # NEW FIELDS
    wins: standing_data[:wins],
    losses: standing_data[:losses],
    ot_losses: standing_data[:ot_losses],
    games_played: standing_data[:games_played],
    goals_for: standing_data[:goals_for],
    goals_against: standing_data[:goals_against],
    goal_diff: standing_data[:goal_diff]
  }
  # ... rest of method
end
```

**Files to Modify:**
- `lib/standings_history_tracker.rb` - Add new fields to storage
- `spec/standings_history_tracker_spec.rb` - Test new fields
- Ensure backward compatibility with existing `standings_history.json`

**Acceptance Criteria:**
- [ ] `standings_history.json` includes new fields after running `ruby update_standings.rb`
- [ ] Existing data format still works (backward compatible)
- [ ] All tests pass with 100% coverage
- [ ] No breaking changes to existing chart

**Data Format Example:**
```json
{
  "SJS": [
    {
      "timestamp": "2025-12-20T12:00:00Z",
      "details": {
        "points": 45,
        "wins": 20,
        "losses": 15,
        "ot_losses": 3,
        "games_played": 38,
        "goals_for": 120,
        "goals_against": 115,
        "goal_diff": 5,
        "division_rank": 3,
        "conference_rank": 7
      }
    }
  ]
}
```

---

### Task 2: Create PredictionTracker Class
**Priority:** 🔴 CRITICAL (blocks Tasks 3-5)  
**Estimated Time:** 3-4 hours  
**Why Critical:** Core data layer for entire prediction feature

**Implementation Details:**
```ruby
# lib/prediction_tracker.rb
require 'json'
require 'fileutils'

class PredictionTracker
  attr_reader :data_file
  
  def initialize(data_file = 'data/predictions.json')
    @data_file = data_file
    ensure_data_file_exists
  end
  
  # Store a prediction (no authentication, just fan name from dropdown)
  def store_prediction(fan_name, game_id, predicted_winner, predicted_at = Time.now)
    data = load_data
    
    # Structure: { "game_id": { "fan_name": { "predicted_winner": "SJS", "predicted_at": "..." }}}
    data[game_id] ||= {}
    data[game_id][fan_name] = {
      'predicted_winner' => predicted_winner,
      'predicted_at' => predicted_at.to_s
    }
    
    save_data(data)
  end
  
  # Get all predictions for a specific game
  def get_predictions(game_id)
    data = load_data
    data[game_id] || {}
  end
  
  # Get all predictions made by a specific fan
  def get_fan_predictions(fan_name)
    data = load_data
    result = {}
    
    data.each do |game_id, predictions|
      if predictions[fan_name]
        result[game_id] = predictions[fan_name]
      end
    end
    
    result
  end
  
  # Get prediction statistics for all fans
  def get_prediction_stats
    data = load_data
    stats = {}
    
    # Count total predictions per fan
    data.each do |game_id, predictions|
      predictions.each do |fan_name, prediction|
        stats[fan_name] ||= { total: 0, games: [] }
        stats[fan_name][:total] += 1
        stats[fan_name][:games] << game_id
      end
    end
    
    stats
  end
  
  private
  
  def load_data
    return {} unless File.exist?(@data_file)
    JSON.parse(File.read(@data_file))
  rescue JSON::ParserError => e
    puts "Warning: Error parsing predictions: #{e.message}"
    {}
  end
  
  def save_data(data)
    FileUtils.mkdir_p(File.dirname(@data_file))
    File.write(@data_file, JSON.pretty_generate(data))
  end
  
  def ensure_data_file_exists
    return if File.exist?(@data_file)
    FileUtils.mkdir_p(File.dirname(@data_file))
    File.write(@data_file, '{}')
  end
end
```

**Files to Create:**
- `lib/prediction_tracker.rb` - Core class
- `spec/prediction_tracker_spec.rb` - Comprehensive tests
- `data/predictions.json` - Auto-created on first use

**Test Cases Required:**
- [ ] Store prediction successfully
- [ ] Retrieve predictions for a game
- [ ] Retrieve all predictions for a fan
- [ ] Handle duplicate predictions (update existing)
- [ ] Handle invalid data gracefully
- [ ] Create data file if missing
- [ ] Parse existing data correctly

---

### Task 3: Create PredictionProcessor Class
**Priority:** 🔴 CRITICAL (blocks Task 5)  
**Estimated Time:** 3-4 hours  
**Why Critical:** Needed to close the prediction loop and calculate accuracy

**Implementation Details:**
```ruby
# lib/prediction_processor.rb
require_relative 'prediction_tracker'

class PredictionProcessor
  def initialize(prediction_tracker = nil)
    @tracker = prediction_tracker || PredictionTracker.new
  end
  
  # Process a completed game and update prediction results
  def process_completed_game(game_id, winner_abbrev)
    predictions = @tracker.get_predictions(game_id)
    results = {}
    
    predictions.each do |fan_name, prediction|
      was_correct = prediction['predicted_winner'] == winner_abbrev
      results[fan_name] = {
        'was_correct' => was_correct,
        'predicted_winner' => prediction['predicted_winner'],
        'actual_winner' => winner_abbrev,
        'processed_at' => Time.now.to_s
      }
    end
    
    # Store results
    save_game_results(game_id, results)
    results
  end
  
  # Calculate prediction accuracy for a specific fan
  def calculate_accuracy(fan_name)
    results = load_all_results
    correct = 0
    total = 0
    
    results.each do |game_id, game_results|
      next unless game_results[fan_name]
      total += 1
      correct += 1 if game_results[fan_name]['was_correct']
    end
    
    {
      fan_name: fan_name,
      correct: correct,
      total: total,
      percentage: total > 0 ? (correct.to_f / total * 100).round(1) : 0.0
    }
  end
  
  # Get leaderboard sorted by accuracy
  def get_leaderboard
    # Get all unique fan names from predictions
    fan_names = get_all_fan_names
    
    leaderboard = fan_names.map do |fan_name|
      calculate_accuracy(fan_name)
    end
    
    # Sort by percentage (descending), then by total (descending)
    leaderboard.sort_by { |stat| [-stat[:percentage], -stat[:total]] }
  end
  
  private
  
  def save_game_results(game_id, results)
    data = load_all_results
    data[game_id] = results
    
    FileUtils.mkdir_p('data')
    File.write('data/prediction_results.json', JSON.pretty_generate(data))
  end
  
  def load_all_results
    file = 'data/prediction_results.json'
    return {} unless File.exist?(file)
    JSON.parse(File.read(file))
  rescue JSON::ParserError
    {}
  end
  
  def get_all_fan_names
    predictions = @tracker.load_data
    names = Set.new
    
    predictions.each do |game_id, game_predictions|
      names.merge(game_predictions.keys)
    end
    
    names.to_a
  end
end
```

**Files to Create:**
- `lib/prediction_processor.rb` - Core class
- `spec/prediction_processor_spec.rb` - Tests
- `data/prediction_results.json` - Auto-created

**Test Cases Required:**
- [ ] Process completed game correctly
- [ ] Calculate accuracy for fan with predictions
- [ ] Calculate accuracy for fan with no predictions (0%)
- [ ] Generate leaderboard sorted correctly
- [ ] Handle games with no predictions
- [ ] Handle ties in leaderboard (sort by total)

---

### Task 4: Build Prediction Voting UI
**Priority:** 🟡 HIGH (depends on Tasks 2-3)  
**Estimated Time:** 3-4 hours  
**Why Important:** User-facing feature that drives engagement

**Implementation Details:**

Update `lib/standings.html.erb` to replace the "Voting opens soon!" placeholder:

```html
<!-- Replace the placeholder voting section (around line 139) -->
<div class="voting-section">
  <h4>Make Your Prediction</h4>
  
  <form id="prediction-form" class="prediction-form">
    <!-- Dropdown with 13 hardcoded fan names -->
    <div class="form-group">
      <label for="fan-select">Your Name:</label>
      <select id="fan-select" name="fan_name" required>
        <option value="">-- Select Your Name --</option>
        <option value="Brian D.">Brian D. (Sharks)</option>
        <option value="David K.">David K. (Predators)</option>
        <option value="Jeff C.">Jeff C. (Avalanche)</option>
        <option value="Keith R.">Keith R. (Ducks)</option>
        <option value="Travis R.">Travis R. (Devils)</option>
        <option value="Zak S.">Zak S. (Knights)</option>
        <option value="Ryan B.">Ryan B. (Sabres)</option>
        <option value="Ryan T.">Ryan T. (Wild)</option>
        <option value="Sean R.">Sean R. (Kings)</option>
        <option value="Tyler F.">Tyler F. (Utah)</option>
        <option value="Trevor R.">Trevor R. (Kraken)</option>
        <option value="Mike M.">Mike M. (Capitals)</option>
        <option value="Dan R.">Dan R. (Jets)</option>
      </select>
    </div>
    
    <!-- Winner selection -->
    <div class="form-group">
      <label>Who will win?</label>
      <div class="winner-buttons">
        <button type="button" class="team-btn" data-team="<%= matchup[:away_abbrev] %>">
          <%= matchup[:away_team] %>
        </button>
        <button type="button" class="team-btn" data-team="<%= matchup[:home_abbrev] %>">
          <%= matchup[:home_team] %>
        </button>
      </div>
    </div>
    
    <input type="hidden" id="game-id" value="<%= matchup[:game_id] %>">
    <input type="hidden" id="predicted-winner" name="predicted_winner">
    
    <button type="submit" id="submit-prediction" class="submit-btn" disabled>
      Submit Prediction
    </button>
  </form>
  
  <div id="prediction-feedback" class="prediction-feedback" style="display: none;">
    <!-- Success/error messages -->
  </div>
  
  <!-- Show current predictions -->
  <div class="current-predictions">
    <h5>Current Predictions:</h5>
    <div id="predictions-list" class="predictions-list">
      <!-- Dynamically loaded -->
    </div>
  </div>
</div>

<script>
// Prediction form handling
(function() {
  const form = document.getElementById('prediction-form');
  const fanSelect = document.getElementById('fan-select');
  const teamButtons = document.querySelectorAll('.team-btn');
  const submitBtn = document.getElementById('submit-prediction');
  const predictedWinnerInput = document.getElementById('predicted-winner');
  const gameId = document.getElementById('game-id').value;
  
  // Team button selection
  teamButtons.forEach(btn => {
    btn.addEventListener('click', function() {
      // Remove active class from all buttons
      teamButtons.forEach(b => b.classList.remove('active'));
      
      // Add active class to clicked button
      this.classList.add('active');
      
      // Set predicted winner
      predictedWinnerInput.value = this.dataset.team;
      
      // Enable submit if fan is selected
      if (fanSelect.value) {
        submitBtn.disabled = false;
      }
    });
  });
  
  // Fan selection
  fanSelect.addEventListener('change', function() {
    if (this.value && predictedWinnerInput.value) {
      submitBtn.disabled = false;
    }
  });
  
  // Form submission
  form.addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const fanName = fanSelect.value;
    const winner = predictedWinnerInput.value;
    
    if (!fanName || !winner) return;
    
    try {
      // For GitHub Pages, we'll use GitHub API to create a file
      // Alternatively, use a GitHub Action with repository dispatch
      const response = await fetch('https://api.github.com/repos/djdefi/hockey_bet/dispatches', {
        method: 'POST',
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          event_type: 'prediction_submitted',
          client_payload: {
            fan_name: fanName,
            game_id: gameId,
            predicted_winner: winner,
            timestamp: new Date().toISOString()
          }
        })
      });
      
      showFeedback('✅ Prediction submitted successfully!', 'success');
      
      // Disable form after submission
      submitBtn.disabled = true;
      submitBtn.textContent = 'Prediction Submitted';
      
    } catch (error) {
      showFeedback('❌ Error submitting prediction. Please try again.', 'error');
    }
  });
  
  function showFeedback(message, type) {
    const feedback = document.getElementById('prediction-feedback');
    feedback.textContent = message;
    feedback.className = `prediction-feedback ${type}`;
    feedback.style.display = 'block';
    
    setTimeout(() => {
      feedback.style.display = 'none';
    }, 5000);
  }
  
  // Load current predictions on page load
  loadCurrentPredictions();
  
  async function loadCurrentPredictions() {
    try {
      // Load from predictions.json (generated by GitHub Action)
      const response = await fetch('data/predictions.json');
      const allPredictions = await response.json();
      const gamePredictions = allPredictions[gameId] || {};
      
      displayPredictions(gamePredictions);
    } catch (error) {
      console.log('No predictions yet');
    }
  }
  
  function displayPredictions(predictions) {
    const list = document.getElementById('predictions-list');
    
    if (Object.keys(predictions).length === 0) {
      list.innerHTML = '<p class="no-predictions">No predictions yet. Be the first!</p>';
      return;
    }
    
    const html = Object.entries(predictions).map(([fan, data]) => {
      return `
        <div class="prediction-item">
          <span class="fan-name">${fan}</span>
          <span class="arrow">→</span>
          <span class="team-name">${data.predicted_winner}</span>
        </div>
      `;
    }).join('');
    
    list.innerHTML = html;
  }
})();
</script>

<style>
.voting-section {
  background: var(--surface-color);
  border-radius: 12px;
  padding: 1.5rem;
  margin-top: 1rem;
}

.prediction-form .form-group {
  margin-bottom: 1rem;
}

.prediction-form label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: var(--text-primary);
}

.prediction-form select {
  width: 100%;
  padding: 0.75rem;
  border-radius: 8px;
  border: 2px solid var(--border-color);
  background: var(--bg-secondary);
  color: var(--text-primary);
  font-size: 1rem;
}

.winner-buttons {
  display: flex;
  gap: 1rem;
}

.team-btn {
  flex: 1;
  padding: 1rem;
  border-radius: 8px;
  border: 2px solid var(--border-color);
  background: var(--bg-secondary);
  color: var(--text-primary);
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.team-btn:hover {
  border-color: var(--accent-color);
  transform: translateY(-2px);
}

.team-btn.active {
  background: var(--accent-color);
  border-color: var(--accent-color);
  color: white;
}

.submit-btn {
  width: 100%;
  padding: 1rem;
  border-radius: 8px;
  border: none;
  background: var(--accent-color);
  color: white;
  font-size: 1rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
  margin-top: 1rem;
}

.submit-btn:hover:not(:disabled) {
  background: var(--accent-hover);
  transform: translateY(-2px);
}

.submit-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.prediction-feedback {
  padding: 1rem;
  border-radius: 8px;
  margin-top: 1rem;
  text-align: center;
  font-weight: 600;
}

.prediction-feedback.success {
  background: #10b98122;
  color: #10b981;
}

.prediction-feedback.error {
  background: #ef444422;
  color: #ef4444;
}

.current-predictions {
  margin-top: 2rem;
}

.predictions-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-top: 1rem;
}

.prediction-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.75rem;
  background: var(--bg-secondary);
  border-radius: 8px;
}

.fan-name {
  font-weight: 600;
  color: var(--text-primary);
}

.arrow {
  color: var(--text-secondary);
}

.team-name {
  font-weight: 700;
  color: var(--accent-color);
}

.no-predictions {
  text-align: center;
  color: var(--text-secondary);
  font-style: italic;
}
</style>
```

**Files to Modify:**
- `lib/standings.html.erb` - Add voting UI and JavaScript
- `lib/styles.css` - Add new styles (or inline as shown)

**Acceptance Criteria:**
- [ ] Dropdown shows all 13 fan names
- [ ] Can select a team to predict
- [ ] Submit button enables only when both selections made
- [ ] Form submits prediction via GitHub API
- [ ] Shows success/error feedback
- [ ] Displays current predictions from JSON file
- [ ] Works on mobile and desktop
- [ ] Accessible (keyboard navigation, screen readers)

---

### Task 5: Add GitHub Action for Prediction Processing
**Priority:** 🟡 HIGH (depends on Tasks 2-4)  
**Estimated Time:** 2-3 hours  
**Why Important:** Closes the prediction loop and calculates results

**Implementation Details:**

Create `.github/workflows/process_predictions.yml`:

```yaml
name: Process Game Predictions

on:
  repository_dispatch:
    types: [prediction_submitted]
  schedule:
    # Run every hour to process completed games
    - cron: '0 * * * *'
  workflow_dispatch:

jobs:
  process_predictions:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.0'
          bundler-cache: true
      
      - name: Handle prediction submission (if triggered by webhook)
        if: github.event_name == 'repository_dispatch'
        run: |
          ruby -e "
          require 'json'
          require_relative 'lib/prediction_tracker'
          
          payload = JSON.parse(ENV['GITHUB_EVENT_PAYLOAD'])
          fan_name = payload['client_payload']['fan_name']
          game_id = payload['client_payload']['game_id']
          predicted_winner = payload['client_payload']['predicted_winner']
          
          tracker = PredictionTracker.new
          tracker.store_prediction(fan_name, game_id, predicted_winner)
          
          puts '✅ Prediction stored successfully'
          "
        env:
          GITHUB_EVENT_PAYLOAD: ${{ toJson(github.event) }}
      
      - name: Process completed games
        run: |
          ruby -e "
          require 'json'
          require 'net/http'
          require_relative 'lib/prediction_tracker'
          require_relative 'lib/prediction_processor'
          
          # Fetch today's completed games from NHL API
          uri = URI('https://api-web.nhle.com/v1/score/now')
          response = Net::HTTP.get_response(uri)
          data = JSON.parse(response.body)
          
          tracker = PredictionTracker.new
          processor = PredictionProcessor.new(tracker)
          
          # Process each completed game
          data['games'].each do |game|
            next unless game['gameState'] == 'OFF' || game['gameState'] == 'FINAL'
            
            game_id = game['id'].to_s
            
            # Determine winner
            home_score = game['homeTeam']['score']
            away_score = game['awayTeam']['score']
            
            if home_score > away_score
              winner = game['homeTeam']['abbrev']
            else
              winner = game['awayTeam']['abbrev']
            end
            
            # Process predictions for this game
            begin
              results = processor.process_completed_game(game_id, winner)
              puts \"✅ Processed game #{game_id}: #{results.length} predictions\"
            rescue => e
              puts \"⚠️  Error processing game #{game_id}: #{e.message}\"
            end
          end
          
          puts '✅ Prediction processing complete'
          "
      
      - name: Commit updated predictions
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add data/predictions.json data/prediction_results.json
          git diff --quiet && git diff --staged --quiet || git commit -m "Update predictions [skip ci]"
          git push
```

**Files to Create:**
- `.github/workflows/process_predictions.yml`

**How It Works:**
1. **Prediction Submission**: When user submits prediction, front-end triggers `repository_dispatch` event
2. **Action Receives Event**: GitHub Action receives the payload and stores prediction in `predictions.json`
3. **Hourly Processing**: Every hour, action fetches completed games from NHL API
4. **Result Calculation**: For each completed game, determine winner and update `prediction_results.json`
5. **Commit & Push**: Changes are committed back to repository
6. **UI Updates**: Next page load shows updated predictions and results

**Acceptance Criteria:**
- [ ] Repository dispatch handler works for new predictions
- [ ] Hourly job processes completed games
- [ ] `predictions.json` and `prediction_results.json` updated correctly
- [ ] Manual trigger works for testing
- [ ] No API rate limit issues
- [ ] Errors logged but don't break workflow

---

## 📊 Phase 2: Enhanced Visualizations (Tasks 6-9)
**Goal:** Increase time on site through better data storytelling  
**Estimated Time:** 8-12 hours total  
**Impact:** +20-30% time on site (based on similar fantasy apps)

### Task 6: Create Goal Differential Chart
**Priority:** 🟢 MEDIUM (depends on Task 1)  
**Estimated Time:** 2-3 hours

**Implementation Details:**

Add new chart function in `lib/standings.html.erb`:

```javascript
async function loadGoalDifferentialChart() {
  try {
    const response = await fetch('data/standings_history.json');
    const data = await response.json();
    
    // Get fan teams from manager_team_map
    const fanTeams = <%= manager_team_map.to_json %>;
    
    const datasets = Object.entries(fanTeams).map(([fan, team]) => {
      const teamData = data[team] || [];
      
      return {
        label: `${fan} (${team})`,
        data: teamData.map(entry => ({
          x: new Date(entry.timestamp),
          y: entry.details.goal_diff || 0
        })),
        borderColor: getTeamColor(team),
        backgroundColor: getTeamColor(team, 0.1),
        borderWidth: 2,
        tension: 0.3
      };
    });
    
    const ctx = document.getElementById('goal-diff-chart').getContext('2d');
    new Chart(ctx, {
      type: 'line',
      data: { datasets },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: 'Goal Differential Over Time',
            color: 'var(--text-primary)',
            font: { size: 16, weight: 'bold' }
          },
          legend: {
            labels: { color: 'var(--text-primary)' }
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                return `${context.dataset.label}: ${context.parsed.y > 0 ? '+' : ''}${context.parsed.y}`;
              }
            }
          }
        },
        scales: {
          x: {
            type: 'time',
            time: {
              unit: 'day',
              tooltipFormat: 'MMM dd'
            },
            ticks: { color: 'var(--text-secondary)' },
            grid: { color: 'var(--border-color)' }
          },
          y: {
            ticks: { 
              color: 'var(--text-secondary)',
              callback: function(value) {
                return value > 0 ? '+' + value : value;
              }
            },
            grid: { color: 'var(--border-color)' }
          }
        }
      }
    });
  } catch (error) {
    console.error('Error loading goal differential chart:', error);
  }
}
```

**HTML Addition:**
```html
<div class="chart-container">
  <canvas id="goal-diff-chart"></canvas>
</div>
```

**Files to Modify:**
- `lib/standings.html.erb` - Add chart HTML and JavaScript

**Acceptance Criteria:**
- [ ] Chart displays goal differential trends over time
- [ ] Shows all 13 fan teams with different colors
- [ ] Positive values shown with + prefix
- [ ] Mobile responsive
- [ ] Loads data from updated `standings_history.json`

---

### Task 7: Create Win/Loss Trends Chart
**Priority:** 🟢 MEDIUM (depends on Task 1)  
**Estimated Time:** 2-3 hours

**Implementation Details:**

Similar to Task 6, create a stacked area chart showing W/L/OTL over time.

```javascript
async function loadWinLossTrendsChart() {
  // Fetch data and create stacked area chart
  // Show wins (green), losses (red), OT losses (yellow)
  // Stack to show total games played
}
```

**Acceptance Criteria:**
- [ ] Stacked area chart shows W/L/OTL breakdown
- [ ] Color-coded (wins=green, losses=red, OT=yellow)
- [ ] Tooltip shows exact counts
- [ ] Can filter to specific fan/team

---

### Task 8: Create Division Rankings Chart
**Priority:** 🟢 MEDIUM (depends on Task 1)  
**Estimated Time:** 2-3 hours

**Implementation Details:**

Create line chart showing division rank position changes over time. Lower is better (rank 1 = best).

```javascript
async function loadDivisionRankingsChart() {
  // Y-axis inverted (lower rank = higher on chart)
  // Show how teams move up/down in division
  // Highlight when team crosses into playoff position (top 3)
}
```

**Acceptance Criteria:**
- [ ] Shows division rank changes over time
- [ ] Y-axis inverted (rank 1 at top)
- [ ] Highlight playoff cutoff line (rank 3)
- [ ] Shows dramatic comebacks/collapses clearly

---

### Task 9: Add Interactive Controls to Charts
**Priority:** 🟢 LOW-MEDIUM  
**Estimated Time:** 2-3 hours

**Implementation Details:**

Add Chart.js zoom plugin and export functionality:

```html
<!-- Add zoom controls -->
<div class="chart-controls">
  <button onclick="resetZoom()">Reset Zoom</button>
  <button onclick="exportChart()">Export as Image</button>
  <label>
    <input type="checkbox" id="show-playoffs-line"> Show Playoff Cutoff
  </label>
</div>
```

**Acceptance Criteria:**
- [ ] Pinch-to-zoom on mobile
- [ ] Mouse wheel zoom on desktop
- [ ] Pan chart by dragging
- [ ] Export as PNG image
- [ ] Toggle playoff cutoff line

---

## ⚡ Phase 3: Real-Time Engagement (Tasks 10-13)
**Goal:** Drive game-day activity and urgency  
**Estimated Time:** 10-14 hours total  
**Impact:** Creates "appointment viewing" during games

### Task 10: Create LiveGameTracker Class
**Priority:** 🟡 HIGH  
**Estimated Time:** 3-4 hours

**Implementation Details:**

```ruby
# lib/live_game_tracker.rb
require 'net/http'
require 'json'
require 'fileutils'

class LiveGameTracker
  LIVE_API_URL = 'https://api-web.nhle.com/v1/score/now'
  
  def initialize(output_file = 'data/live_games.json')
    @output_file = output_file
  end
  
  def fetch_live_scores
    uri = URI(LIVE_API_URL)
    response = Net::HTTP.get_response(uri)
    
    return nil unless response.is_a?(Net::HTTPSuccess)
    
    data = JSON.parse(response.body)
    process_live_data(data)
  end
  
  def process_live_data(api_data)
    live_games = []
    
    api_data['games'].each do |game|
      # Only include games that are live or recently final
      next unless ['LIVE', 'CRIT', 'PRE'].include?(game['gameState'])
      
      live_games << {
        game_id: game['id'],
        state: game['gameState'],
        period: game['period'],
        time_remaining: game['clock']&.[]('timeRemaining'),
        home_team: {
          abbrev: game['homeTeam']['abbrev'],
          score: game['homeTeam']['score'],
          shots: game['homeTeam']['sog']
        },
        away_team: {
          abbrev: game['awayTeam']['abbrev'],
          score: game['awayTeam']['score'],
          shots: game['awayTeam']['sog']
        }
      }
    end
    
    save_live_games(live_games)
    live_games
  end
  
  private
  
  def save_live_games(games)
    data = {
      last_updated: Time.now.to_s,
      games: games
    }
    
    FileUtils.mkdir_p(File.dirname(@output_file))
    File.write(@output_file, JSON.pretty_generate(data))
  end
end
```

**Files to Create:**
- `lib/live_game_tracker.rb`
- `spec/live_game_tracker_spec.rb`
- `data/live_games.json` (generated)

**Acceptance Criteria:**
- [ ] Fetches live game data from NHL API
- [ ] Parses game state, scores, period, time
- [ ] Saves to JSON file
- [ ] Handles API errors gracefully
- [ ] Tests with fixtures

---

### Task 11: Add GitHub Action for Live Updates
**Priority:** 🟡 HIGH (depends on Task 10)  
**Estimated Time:** 2-3 hours

**Implementation Details:**

Create `.github/workflows/update_live_scores.yml`:

```yaml
name: Update Live Scores

on:
  schedule:
    # Run every 5 minutes during typical game hours (4 PM - 11 PM PT)
    - cron: '*/5 0-7 * * *'  # 5 PM - 12 AM PT
  workflow_dispatch:

jobs:
  update_scores:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.0'
          bundler-cache: true
      
      - name: Fetch live game scores
        run: |
          ruby -e "
          require_relative 'lib/live_game_tracker'
          
          tracker = LiveGameTracker.new
          games = tracker.fetch_live_scores
          
          if games && games.any?
            puts \"✅ Updated #{games.length} live games\"
          else
            puts \"ℹ️  No live games right now\"
          end
          "
      
      - name: Commit live scores
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add data/live_games.json
          git diff --quiet && git diff --staged --quiet || git commit -m "Update live scores [skip ci]"
          git push
```

**Optimization:** Consider using GitHub Pro ($4/month) for more frequent actions during playoffs.

**Acceptance Criteria:**
- [ ] Runs every 5 minutes during game windows
- [ ] Updates `live_games.json`
- [ ] Commits changes
- [ ] Doesn't run during off-hours (efficiency)
- [ ] Manual trigger works

---

### Task 12: Build Live Scores UI
**Priority:** 🟡 HIGH (depends on Tasks 10-11)  
**Estimated Time:** 3-4 hours

**Implementation Details:**

Add live scores widget to `lib/standings.html.erb`:

```html
<div id="live-games-widget" class="live-games-widget">
  <h3>🔴 Live Games</h3>
  <div id="live-games-container">
    <!-- Populated by JavaScript -->
  </div>
</div>

<script>
async function loadLiveGames() {
  try {
    const response = await fetch('data/live_games.json');
    const data = await response.json();
    
    displayLiveGames(data.games);
    
    // Auto-refresh every 30 seconds
    setTimeout(loadLiveGames, 30000);
  } catch (error) {
    console.error('Error loading live games:', error);
  }
}

function displayLiveGames(games) {
  const container = document.getElementById('live-games-container');
  
  if (!games || games.length === 0) {
    container.innerHTML = '<p class="no-live-games">No live games right now</p>';
    return;
  }
  
  const html = games.map(game => `
    <div class="live-game-card">
      <div class="game-status">
        <span class="live-indicator">🔴 LIVE</span>
        <span class="period-time">
          ${formatPeriod(game.period)} - ${game.time_remaining || ''}
        </span>
      </div>
      
      <div class="game-matchup">
        <div class="team ${isWinning(game, 'away') ? 'winning' : ''}">
          <span class="team-abbrev">${game.away_team.abbrev}</span>
          <span class="team-score">${game.away_team.score}</span>
          <span class="team-shots">${game.away_team.shots} SOG</span>
        </div>
        
        <div class="game-divider">@</div>
        
        <div class="team ${isWinning(game, 'home') ? 'winning' : ''}">
          <span class="team-abbrev">${game.home_team.abbrev}</span>
          <span class="team-score">${game.home_team.score}</span>
          <span class="team-shots">${game.home_team.shots} SOG</span>
        </div>
      </div>
    </div>
  `).join('');
  
  container.innerHTML = html;
}

function formatPeriod(period) {
  if (period === 1) return '1st';
  if (period === 2) return '2nd';
  if (period === 3) return '3rd';
  if (period > 3) return 'OT';
  return 'Pre-game';
}

function isWinning(game, side) {
  if (side === 'home') {
    return game.home_team.score > game.away_team.score;
  } else {
    return game.away_team.score > game.home_team.score;
  }
}

// Start loading live games on page load
document.addEventListener('DOMContentLoaded', loadLiveGames);
</script>

<style>
.live-games-widget {
  background: var(--surface-color);
  border-radius: 12px;
  padding: 1.5rem;
  margin-bottom: 2rem;
}

.live-indicator {
  color: #ef4444;
  font-weight: 700;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}

.live-game-card {
  background: var(--bg-secondary);
  border-radius: 8px;
  padding: 1rem;
  margin-top: 1rem;
}

.game-status {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.75rem;
  font-size: 0.875rem;
}

.game-matchup {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.team {
  flex: 1;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.team.winning {
  font-weight: 700;
}

.team-score {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--accent-color);
}

.team-shots {
  font-size: 0.875rem;
  color: var(--text-secondary);
}

.no-live-games {
  text-align: center;
  color: var(--text-secondary);
  font-style: italic;
  padding: 2rem;
}
</style>
```

**Acceptance Criteria:**
- [ ] Shows all live games
- [ ] Auto-refreshes every 30 seconds
- [ ] Highlights winning team
- [ ] Shows period and time remaining
- [ ] Shows shots on goal
- [ ] Mobile responsive
- [ ] Works when no live games

---

### Task 13: Add Live Indicators to Tables
**Priority:** 🟢 LOW-MEDIUM  
**Estimated Time:** 2-3 hours

**Implementation Details:**

Modify standings table to show "🔴 LIVE" next to teams currently playing:

```javascript
function updateLiveIndicators() {
  // Load live_games.json
  // Find which teams are playing
  // Add pulsing live indicator to their rows in the table
  // Update every 30 seconds
}
```

**Acceptance Criteria:**
- [ ] Table rows show 🔴 LIVE for active games
- [ ] Indicator pulses/animates
- [ ] Auto-updates
- [ ] Links to live games widget

---

## 🔔 Phase 4: Retention Features (Tasks 14-17)
**Goal:** Keep users coming back daily  
**Estimated Time:** 10-14 hours total  
**Impact:** Increases return rate and daily check-ins

### Task 14: Implement Web Push Notifications
**Priority:** 🟡 MEDIUM  
**Estimated Time:** 4-5 hours

**Implementation Details:**

Add web push notification support using browser Push API:

```javascript
// Request notification permission
async function requestNotificationPermission() {
  if ('Notification' in window && 'serviceWorker' in navigator) {
    const permission = await Notification.requestPermission();
    
    if (permission === 'granted') {
      // Store permission locally
      localStorage.setItem('notifications_enabled', 'true');
      subscribeToNotifications();
    }
  }
}

// Subscribe to push notifications
async function subscribeToNotifications() {
  const registration = await navigator.serviceWorker.ready;
  
  // Use public VAPID key (configure in environment)
  const subscription = await registration.pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: urlBase64ToUint8Array(PUBLIC_VAPID_KEY)
  });
  
  // Send subscription to server (GitHub Action)
  await fetch('/.netlify/functions/subscribe', {
    method: 'POST',
    body: JSON.stringify(subscription)
  });
}
```

**Service Worker (`sw.js`):**
```javascript
self.addEventListener('push', function(event) {
  const data = event.data.json();
  
  const options = {
    body: data.body,
    icon: '/favicon-32x32.png',
    badge: '/favicon-32x32.png',
    data: {
      url: data.url || '/'
    }
  };
  
  event.waitUntil(
    self.registration.showNotification(data.title, options)
  );
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  event.waitUntil(
    clients.openWindow(event.notification.data.url)
  );
});
```

**Alternative:** Use Firebase Cloud Messaging (free tier) for simpler setup.

**Files to Create:**
- `sw.js` - Service worker
- Update `lib/standings.html.erb` - Add notification UI

**Acceptance Criteria:**
- [ ] "Enable Notifications" button in UI
- [ ] Requests browser permission
- [ ] Subscribes to push service
- [ ] Service worker registered
- [ ] Test notification works

---

### Task 15: Add Notification Triggers
**Priority:** 🟡 MEDIUM (depends on Task 14)  
**Estimated Time:** 3-4 hours

**Implementation Details:**

Add GitHub Action to send notifications for key events:

```yaml
name: Send Notifications

on:
  schedule:
    - cron: '0 16 * * *'  # 4 PM PT - pre-game reminders
    - cron: '0 23 * * *'  # 11 PM PT - game results
  workflow_dispatch:

jobs:
  send_notifications:
    runs-on: ubuntu-latest
    steps:
      - name: Check games and send notifications
        run: |
          # Fetch today's games
          # For each fan team playing:
          #   - Send reminder 1 hour before game
          #   - Send result after game ends
          #   - Send prediction accuracy update
```

**Notification Types:**
1. **Pre-game reminder**: "Your Sharks play in 1 hour!"
2. **Game result**: "Sharks won 3-2! You're up to 45 points."
3. **Prediction result**: "You got 3/4 predictions right today!"
4. **Weekly digest**: "This week: 5 wins, 2 losses, 83% accuracy"

**Acceptance Criteria:**
- [ ] Pre-game reminders sent 1 hour before
- [ ] Results sent after games end
- [ ] Prediction accuracy updates
- [ ] Users can customize notification preferences

---

### Task 16: Create Weekly Digest
**Priority:** 🟢 LOW-MEDIUM  
**Estimated Time:** 2-3 hours

**Implementation Details:**

Generate weekly summary with:
- Team performance this week
- Prediction accuracy
- League standings changes
- Upcoming featured matchups

Can be sent via:
- Email (using GitHub Actions + email service)
- Web push notification
- In-app notification banner

**Acceptance Criteria:**
- [ ] Weekly digest generated every Monday
- [ ] Includes all 13 fans' stats
- [ ] Highlights biggest movers
- [ ] Preview of next week's matchups

---

### Task 17: Add Achievement Badges
**Priority:** 🟢 LOW-MEDIUM  
**Estimated Time:** 2-3 hours

**Implementation Details:**

Add badges/achievements to League page:

**Badge Types:**
- 🎯 **Perfect Week** - 7/7 predictions correct
- 🔥 **Hot Streak** - 5+ correct in a row
- 📈 **Comeback Kid** - Team came from behind in division
- 🧊 **Cold Spell** - 5+ incorrect in a row
- 🏆 **Cup Favorite** - Best playoff odds
- 🛡️ **Brick Wall** - Best goals against
- ⚔️ **Glass Cannon** - High scoring, weak defense

**Implementation:**
```ruby
# lib/achievement_calculator.rb
class AchievementCalculator
  def calculate_achievements(fan_name, stats)
    achievements = []
    
    # Check for streaks
    if has_perfect_week?(fan_name)
      achievements << { icon: '🎯', name: 'Perfect Week', description: '7/7 predictions' }
    end
    
    # ... more checks ...
    
    achievements
  end
end
```

**Acceptance Criteria:**
- [ ] Badges displayed on League page
- [ ] Calculated automatically
- [ ] Tooltips explain how to earn
- [ ] Celebration animation when earned

---

## 🎯 Phase 5: Polish & Optimization (Tasks 18-20)
**Goal:** Maximize performance and user experience  
**Estimated Time:** 6-8 hours total  
**Impact:** Faster load times, better reliability

### Task 18: Add Response Caching
**Priority:** 🟢 LOW  
**Estimated Time:** 2-3 hours

**Implementation Details:**

Cache NHL API responses to reduce calls:

```ruby
# lib/api_cache.rb
class ApiCache
  CACHE_DIR = 'data/cache'
  CACHE_DURATION = 300 # 5 minutes
  
  def fetch_with_cache(url, cache_key)
    cache_file = File.join(CACHE_DIR, "#{cache_key}.json")
    
    # Check if cache exists and is fresh
    if File.exist?(cache_file) && 
       (Time.now - File.mtime(cache_file)) < CACHE_DURATION
      return JSON.parse(File.read(cache_file))
    end
    
    # Fetch fresh data
    response = fetch_from_api(url)
    
    # Save to cache
    FileUtils.mkdir_p(CACHE_DIR)
    File.write(cache_file, JSON.pretty_generate(response))
    
    response
  end
end
```

**Acceptance Criteria:**
- [ ] API responses cached for 5 minutes
- [ ] Reduces API calls by ~80%
- [ ] Transparent to other code
- [ ] Cache directory in .gitignore

---

### Task 19: Optimize GitHub Actions
**Priority:** 🟢 LOW  
**Estimated Time:** 2-3 hours

**Implementation Details:**

Reduce GitHub Actions runtime and costs:

1. **Smart scheduling**: Only run during NHL season
2. **Conditional execution**: Skip if no games today
3. **Batch operations**: Combine related updates
4. **Efficient caching**: Cache Ruby gems and dependencies

```yaml
- name: Check if games today
  id: check_games
  run: |
    # Query NHL API for today's games
    # Exit early if none found
    
- name: Update standings
  if: steps.check_games.outputs.has_games == 'true'
  run: ruby update_standings.rb
```

**Acceptance Criteria:**
- [ ] Actions run only when needed
- [ ] Reduced by ~50% runtime
- [ ] Smart caching implemented
- [ ] Season detection works

---

### Task 20: Add PWA Offline Capabilities
**Priority:** 🟢 LOW  
**Estimated Time:** 2-3 hours

**Implementation Details:**

Enhance service worker to cache pages for offline viewing:

```javascript
// sw.js - Cache strategy
const CACHE_NAME = 'hockey-bet-v1';
const urlsToCache = [
  '/',
  '/styles.css',
  '/vendor/chart.umd.js',
  '/data/standings_history.json'
];

self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', function(event) {
  event.respondWith(
    caches.match(event.request)
      .then(response => response || fetch(event.request))
  );
});
```

**Acceptance Criteria:**
- [ ] Works offline (shows cached data)
- [ ] "Update available" notification
- [ ] Seamless online/offline transition
- [ ] Home screen icon works

---

## 📈 Impact Summary

### Expected Outcomes After All 20 Tasks

**User Engagement:**
- Daily Active Users: 25% → **70%** (3-4 fans → 9-10 fans)
- Time on Site: 2 min → **6-8 min** (+200-300%)
- Return Rate: Weekly → **Daily**

**Feature Completeness:**
- ✅ Interactive predictions with leaderboard
- ✅ Real-time live game tracking
- ✅ Rich data visualizations (4+ charts)
- ✅ Push notifications for key events
- ✅ Achievement system with badges
- ✅ Optimized performance and caching
- ✅ Full offline PWA support

**Cost:**
- **$0/month** if using free GitHub tier (3-hour updates)
- **$4/month** for GitHub Pro (5-minute live updates during games)

**Implementation Time:**
- **Phase 1 (Foundation):** 2-3 weeks
- **Phase 2 (Visualizations):** 1-2 weeks
- **Phase 3 (Real-time):** 2-3 weeks
- **Phase 4 (Retention):** 2-3 weeks
- **Phase 5 (Polish):** 1 week
- **Total:** 8-12 weeks for all features

---

## 🎯 Recommended Execution Strategy

### Sprint 1 (Weeks 1-3): Game Predictions
Focus on Tasks 1-5 to unlock primary engagement driver.

**Why Start Here:**
- Biggest impact on DAU (2-3x increase)
- Creates daily habit of checking site
- Relatively self-contained (no external dependencies)
- Quick win that demonstrates value

**Success Metric:** 8-10 fans making predictions daily

---

### Sprint 2 (Weeks 4-5): Enhanced Charts
Complete Tasks 6-9 for better data storytelling.

**Why Second:**
- Builds on Task 1 foundation
- Increases time on site
- Relatively quick wins (low effort)
- Makes site more valuable for all users

**Success Metric:** +30% increase in time on site

---

### Sprint 3 (Weeks 6-8): Real-Time Features
Implement Tasks 10-13 for game-day excitement.

**Why Third:**
- Creates "appointment viewing" during games
- More complex implementation (needs testing)
- Builds on prediction feature (shows live accuracy)

**Success Metric:** 10+ fans active during game nights

---

### Sprint 4 (Weeks 9-11): Retention Features
Add Tasks 14-17 to keep users coming back.

**Why Fourth:**
- Requires other features to be valuable
- Notifications need content (predictions, scores)
- Can be phased (start with basic, enhance later)

**Success Metric:** Daily return rate >60%

---

### Sprint 5 (Week 12): Polish & Optimization
Clean up with Tasks 18-20.

**Why Last:**
- Optimization makes sense with traffic
- PWA features enhance existing functionality
- Polish after feature-complete

**Success Metric:** <2s page load time, 90+ Lighthouse score

---

## 🚀 Quick Start Guide

**For AI Agents:**

1. Read this document completely
2. Pick tasks in order (respect dependencies)
3. Follow implementation guides precisely
4. Run tests after each task
5. Update progress tracking

**For Humans:**

1. Review and approve this plan
2. Prioritize based on your timeline
3. Assign tasks to AI agents
4. Monitor progress via checklist
5. Test features as they're completed

---

## 📚 Related Documentation

- **[ROADMAP.md](ROADMAP.md)** - Original comprehensive roadmap (PR #193)
- **[INFRASTRUCTURE.md](https://github.com/djdefi/hockey_bet/blob/copilot/create-roadmap-for-improvements/INFRASTRUCTURE.md)** - Technical architecture details
- **[ROADMAP_CONTEXT.md](https://github.com/djdefi/hockey_bet/blob/copilot/create-roadmap-for-improvements/ROADMAP_CONTEXT.md)** - Target audience and methodology
- **[TASKS.md](https://github.com/djdefi/hockey_bet/blob/copilot/create-roadmap-for-improvements/TASKS.md)** - Original task backlog from PR #193

---

**Last Updated:** December 21, 2025  
**Status:** Ready for Implementation  
**Next Action:** Begin Sprint 1 (Tasks 1-5) for game predictions feature
