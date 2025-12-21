# Quick Start Guide: Task 1 - Enhance StandingsHistoryTracker

> **Start here** to implement the first task in the strategic plan  
> **Time Estimate:** 2-3 hours  
> **Difficulty:** Medium  
> **Why First:** Unlocks all Phase 2 chart visualizations

---

## 📋 What You're Building

Currently, `standings_history.json` only stores:
- Points
- Division rank
- Conference rank

After this task, it will also store:
- Wins, Losses, OT Losses
- Goals For, Goals Against, Goal Differential
- Games Played

This additional data enables 4 new chart visualizations (Tasks 6-9).

---

## 🎯 Acceptance Criteria

- [ ] `standings_history.json` includes 7 new fields after running `ruby update_standings.rb`
- [ ] Existing data format still works (backward compatible)
- [ ] All existing tests pass
- [ ] New tests pass with 100% coverage for new fields
- [ ] No breaking changes to existing chart
- [ ] Data validates correctly (e.g., wins + losses + ot_losses = games_played)

---

## 📁 Files You'll Modify

### Primary Files
1. **lib/standings_history_tracker.rb** - Add new fields to storage
2. **spec/standings_history_tracker_spec.rb** - Add tests for new fields

### Files to Review (Don't Modify Yet)
- `lib/standings_processor.rb` - See how it calls the tracker
- `data/standings_history.json` - Current data format
- `lib/standings.html.erb` - Where the chart is rendered

---

## 🔍 Step 1: Understand Current Implementation

### Current Code (lib/standings_history_tracker.rb)

```ruby
def record_standing(team_abbrev, timestamp, standing_data)
  data = load_data
  data[team_abbrev] ||= []
  
  # Current implementation only stores these 3 fields:
  data[team_abbrev] << {
    'timestamp' => timestamp.to_s,
    'details' => {
      'points' => standing_data[:points],
      'division_rank' => standing_data[:division_rank],
      'conference_rank' => standing_data[:conference_rank]
    }
  }
  
  save_data(data)
end
```

### Current Data Format (standings_history.json)

```json
{
  "SJS": [
    {
      "timestamp": "2025-12-20T12:00:00Z",
      "details": {
        "points": 45,
        "division_rank": 3,
        "conference_rank": 7
      }
    }
  ]
}
```

---

## 🛠️ Step 2: Make the Changes

### Modify lib/standings_history_tracker.rb

**Find the `record_standing` method and update it:**

```ruby
def record_standing(team_abbrev, timestamp, standing_data)
  data = load_data
  data[team_abbrev] ||= []
  
  # Enhanced with 7 new fields
  data[team_abbrev] << {
    'timestamp' => timestamp.to_s,
    'details' => {
      # Existing fields
      'points' => standing_data[:points],
      'division_rank' => standing_data[:division_rank],
      'conference_rank' => standing_data[:conference_rank],
      
      # NEW FIELDS - Add these
      'wins' => standing_data[:wins],
      'losses' => standing_data[:losses],
      'ot_losses' => standing_data[:ot_losses],
      'games_played' => standing_data[:games_played],
      'goals_for' => standing_data[:goals_for],
      'goals_against' => standing_data[:goals_against],
      'goal_diff' => standing_data[:goal_diff]
    }
  }
  
  save_data(data)
end
```

**That's it!** The method is now enhanced to store the additional fields.

---

## 🧪 Step 3: Add Tests

### Add to spec/standings_history_tracker_spec.rb

**Add this test case:**

```ruby
describe '#record_standing' do
  # ... existing tests ...
  
  it 'stores extended statistics' do
    timestamp = Time.parse('2025-01-15 12:00:00 UTC')
    
    standing_data = {
      points: 50,
      division_rank: 2,
      conference_rank: 5,
      wins: 22,
      losses: 12,
      ot_losses: 4,
      games_played: 38,
      goals_for: 125,
      goals_against: 110,
      goal_diff: 15
    }
    
    tracker.record_standing('SJS', timestamp, standing_data)
    
    data = tracker.load_data
    latest = data['SJS'].last
    
    # Verify all new fields are stored
    expect(latest['details']['wins']).to eq(22)
    expect(latest['details']['losses']).to eq(12)
    expect(latest['details']['ot_losses']).to eq(4)
    expect(latest['details']['games_played']).to eq(38)
    expect(latest['details']['goals_for']).to eq(125)
    expect(latest['details']['goals_against']).to eq(110)
    expect(latest['details']['goal_diff']).to eq(15)
  end
  
  it 'is backward compatible with old data format' do
    # Create old format data (missing new fields)
    old_data = {
      'SJS' => [
        {
          'timestamp' => '2025-01-01T00:00:00Z',
          'details' => {
            'points' => 40,
            'division_rank' => 3,
            'conference_rank' => 8
          }
        }
      ]
    }
    
    # Manually save old format
    File.write(tracker.data_file, JSON.pretty_generate(old_data))
    
    # Should load without errors
    data = tracker.load_data
    expect(data['SJS'].length).to eq(1)
    
    # Old data should still be readable
    expect(data['SJS'][0]['details']['points']).to eq(40)
    
    # New fields should be absent (not cause errors)
    expect(data['SJS'][0]['details']['wins']).to be_nil
  end
  
  it 'validates that games played equals wins + losses + ot_losses' do
    standing_data = {
      points: 50,
      division_rank: 2,
      conference_rank: 5,
      wins: 22,
      losses: 12,
      ot_losses: 4,
      games_played: 38  # 22 + 12 + 4 = 38 ✓
    }
    
    tracker.record_standing('SJS', Time.now, standing_data)
    
    data = tracker.load_data
    latest = data['SJS'].last
    
    total = latest['details']['wins'] + 
            latest['details']['losses'] + 
            latest['details']['ot_losses']
    
    expect(total).to eq(latest['details']['games_played'])
  end
end
```

---

## ✅ Step 4: Run Tests

```bash
cd /home/runner/work/hockey_bet/hockey_bet
bundle exec rspec spec/standings_history_tracker_spec.rb
```

**Expected output:**
```
StandingsHistoryTracker
  #record_standing
    stores basic standing information
    stores extended statistics ✓
    is backward compatible with old data format ✓
    validates that games played equals wins + losses + ot_losses ✓

Finished in 0.05 seconds
4 examples, 0 failures
```

---

## 🔄 Step 5: Update the Data

The tracker needs to receive the new fields. Check where it's called:

### Find in lib/standings_processor.rb

Look for where `StandingsHistoryTracker#record_standing` is called:

```ruby
# This is likely around line 50-80 in standings_processor.rb
standings.each do |standing|
  team_abbrev = standing[:team_abbrev]
  
  standing_data = {
    points: standing[:points],
    division_rank: standing[:divisionSequence],
    conference_rank: standing[:conferenceSequence],
    # ADD THESE NEW FIELDS
    wins: standing[:wins],
    losses: standing[:losses],
    ot_losses: standing[:otLosses],
    games_played: standing[:gamesPlayed],
    goals_for: standing[:goalFor],
    goals_against: standing[:goalAgainst],
    goal_diff: standing[:goalDifferential]
  }
  
  history_tracker.record_standing(team_abbrev, timestamp, standing_data)
end
```

**Note:** The exact field names depend on the NHL API response. Check `spec/fixtures/teams.json` to see the actual field names.

---

## 🔍 Step 6: Verify NHL API Fields

### Check the API Response Format

```ruby
# Create a test script: test_nhl_api.rb
require 'net/http'
require 'json'

uri = URI('https://api-web.nhle.com/v1/standings/now')
response = Net::HTTP.get_response(uri)
data = JSON.parse(response.body)

# Print the first standing to see field names
puts JSON.pretty_generate(data['standings'].first)
```

Run it:
```bash
ruby test_nhl_api.rb
```

**Look for these fields:**
```json
{
  "wins": 25,
  "losses": 10,
  "otLosses": 3,
  "gamesPlayed": 38,
  "goalFor": 120,
  "goalAgainst": 105,
  "goalDifferential": 15
}
```

**If field names are different, adjust accordingly.**

---

## 🎨 Step 7: Update standings_processor.rb

### Find where standings are processed

```ruby
# lib/standings_processor.rb (around line 60-90)

def track_standings_history(standings, timestamp)
  standings.each do |standing|
    team_abbrev = standing[:teamAbbrev][:default] rescue standing[:teamCommonName]
    
    standing_data = {
      points: standing[:points],
      division_rank: standing[:divisionSequence],
      conference_rank: standing[:conferenceSequence],
      
      # ADD THESE NEW FIELDS (verify exact keys from API)
      wins: standing[:wins],
      losses: standing[:losses],
      ot_losses: standing[:otLosses],
      games_played: standing[:gamesPlayed],
      goals_for: standing[:goalFor],
      goals_against: standing[:goalAgainst],
      goal_diff: standing[:goalDifferential]
    }
    
    @history_tracker.record_standing(team_abbrev, timestamp, standing_data)
  end
end
```

---

## 🧪 Step 8: Integration Test

### Test the entire flow:

```bash
# 1. Run the update script
ruby update_standings.rb

# 2. Check the output file
cat data/standings_history.json | jq '.SJS[-1]'
```

**Expected output:**
```json
{
  "timestamp": "2025-12-21T00:00:00Z",
  "details": {
    "points": 45,
    "division_rank": 3,
    "conference_rank": 7,
    "wins": 20,
    "losses": 15,
    "ot_losses": 3,
    "games_played": 38,
    "goals_for": 125,
    "goals_against": 120,
    "goal_diff": 5
  }
}
```

**If you see all the new fields, SUCCESS! ✅**

---

## 🐛 Troubleshooting

### Problem: Tests fail with "undefined method"

**Solution:** Make sure you added the fields to both:
1. `standings_history_tracker.rb` (storage)
2. `standings_processor.rb` (data source)

### Problem: Data file has `nil` values

**Solution:** The NHL API field names might be different. Run the test script from Step 6 to verify exact field names.

### Problem: Existing chart breaks

**Solution:** This shouldn't happen if you followed backward compatibility. Check that old data without new fields still loads.

### Problem: Values don't add up (wins + losses + ot ≠ games)

**Solution:** Some teams might have shootout losses counted separately. Check NHL API documentation or adjust validation.

---

## ✅ Completion Checklist

- [ ] Modified `lib/standings_history_tracker.rb`
- [ ] Added new tests to `spec/standings_history_tracker_spec.rb`
- [ ] All tests pass (green)
- [ ] Modified `lib/standings_processor.rb` to pass new fields
- [ ] Ran `ruby update_standings.rb` successfully
- [ ] Verified `standings_history.json` has new fields
- [ ] Checked that existing chart still works
- [ ] Backward compatibility confirmed

---

## 🎉 What You've Accomplished

You've now:
✅ Enhanced the data model with 7 new fields  
✅ Maintained backward compatibility  
✅ Added comprehensive tests  
✅ Unlocked Phase 2 (Tasks 6-9)

**Next Steps:**
- Task 6: Create Goal Differential Chart (now possible!)
- Task 7: Create Win/Loss Trends Chart (now possible!)
- Task 8: Create Division Rankings Chart (now possible!)

---

## 📚 Reference

- **Full task details:** [NEXT_TASKS.md](NEXT_TASKS.md#task-1-enhance-standingshistorytracker-for-chart-data)
- **Dependency map:** [TASK_DEPENDENCIES.md](TASK_DEPENDENCIES.md)
- **Quick summary:** [TASK_SUMMARY.md](TASK_SUMMARY.md)

---

**Estimated time:** 2-3 hours  
**Difficulty:** Medium  
**Impact:** 🔥 (Unlocks all visualization enhancements)

Good luck! 🚀
