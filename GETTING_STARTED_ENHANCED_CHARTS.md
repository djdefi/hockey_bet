# Getting Started: Enhanced Trend Charts

> **First Implementation from the Roadmap** - Quick start guide

This guide will help you implement the first P0 feature: Enhanced Trend Visualizations.

---

## 🎯 Why Start Here?

- ✅ **Low effort** (1-2 weeks)
- ✅ **High value** (+30% time on site)
- ✅ **Low risk** (uses existing data & libraries)
- ✅ **Quick win** (builds momentum)
- ✅ **No backend changes** (frontend only)

---

## 📊 What You're Building

Add 4 new chart visualizations to complement the existing standings trend chart:

1. **Win/Loss Distribution Chart** - Stacked bar chart showing W/L/OTL breakdown
2. **Goal Differential Trend** - Line chart showing scoring margin over time
3. **Points Per Game Chart** - Compare points earned per game (efficiency metric)
4. **Division Rankings Over Time** - Animated line chart of division positions

---

## 📁 Files You'll Modify

```
lib/
  └── standings.html.erb          # Main template (add new chart sections)
  
_site/
  └── standings_history.json      # Already has the data you need!
  └── index.html                  # Will be regenerated
```

**No Ruby code changes needed!** This is purely frontend JavaScript/Chart.js.

---

## 🚀 Step-by-Step Implementation

### Step 1: Review Existing Chart (15 minutes)

Open `lib/standings.html.erb` and search for "loadStandingsTrendChart" (approximately around line 5900, though line numbers may vary):

```javascript
async function loadStandingsTrendChart() {
    // This is your template to copy!
    // Shows how to:
    // - Fetch standings_history.json
    // - Parse the data
    // - Create Chart.js configuration
    // - Handle errors
}
```

**Study this function first.** You'll follow the same pattern.

**Note:** Line numbers are approximate and may change as the file is updated. Use your editor's search function (Ctrl+F or Cmd+F) to find the function.

---

### Step 2: Add Chart Containers (30 minutes)

In `lib/standings.html.erb`, search for the Trends tab section (approximately around line 4720, use search to locate) and add new chart sections:

```html
<!-- Existing chart -->
<div class="chart-container border rounded-2 mb-3">
    <h2 class='h3 mb-3'>📈 Fan League Standings Trend 📈</h2>
    <canvas id="leagueTrendChart"></canvas>
</div>

<!-- NEW CHART 1: Win/Loss Distribution -->
<div class="chart-container border rounded-2 mb-3">
    <h2 class='h3 mb-3'>🎯 Win/Loss Distribution 🎯</h2>
    <canvas id="winLossChart"></canvas>
</div>

<!-- NEW CHART 2: Goal Differential -->
<div class="chart-container border rounded-2 mb-3">
    <h2 class='h3 mb-3'>⚡ Goal Differential Trend ⚡</h2>
    <canvas id="goalDiffChart"></canvas>
</div>

<!-- NEW CHART 3: Points Per Game -->
<div class="chart-container border rounded-2 mb-3">
    <h2 class='h3 mb-3'>💎 Points Per Game Efficiency 💎</h2>
    <canvas id="ppgChart"></canvas>
</div>

<!-- NEW CHART 4: Division Rankings -->
<div class="chart-container border rounded-2 mb-3">
    <h2 class='h3 mb-3'>🏆 Division Rankings Over Time 🏆</h2>
    <canvas id="divisionRankChart"></canvas>
</div>
```

---

### Step 3: Implement Chart Functions (2-3 hours)

Add these functions to the `<script>` section:

#### Chart 1: Win/Loss Distribution

```javascript
async function loadWinLossChart() {
    try {
        const historyResponse = await fetch('standings_history.json');
        const history = await historyResponse.json();
        
        if (!history || history.length === 0) {
            document.getElementById('winLossChart').parentElement.innerHTML = 
                '<p class="text-secondary" style="text-align: center; padding: 2rem;">No data available yet.</p>';
            return;
        }
        
        // Get latest standings snapshot
        const latest = history[history.length - 1];
        
        // TODO: You'll need to enhance StandingsHistoryTracker first (see Step 4)
        // to include W/L/OTL data in the 'details' object
        // For now, this shows the structure you'll need:
        
        // Extract fan names and their stats
        const fanNames = Object.keys(latest.standings);
        const winsData = [];  // TODO: Extract from latest.details[fan].wins
        const lossesData = []; // TODO: Extract from latest.details[fan].losses  
        const otlData = [];    // TODO: Extract from latest.details[fan].ot_losses
        
        // Once StandingsHistoryTracker is enhanced, populate like this:
        // fanNames.forEach(fan => {
        //     winsData.push(latest.details[fan].wins);
        //     lossesData.push(latest.details[fan].losses);
        //     otlData.push(latest.details[fan].ot_losses);
        // });
        
        const ctx = document.getElementById('winLossChart').getContext('2d');
        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: fanNames,
                datasets: [
                    {
                        label: 'Wins',
                        data: winsData,
                        backgroundColor: 'rgba(76, 175, 80, 0.8)'
                    },
                    {
                        label: 'Losses',
                        data: lossesData,
                        backgroundColor: 'rgba(244, 67, 54, 0.8)'
                    },
                    {
                        label: 'OT Losses',
                        data: otlData,
                        backgroundColor: 'rgba(255, 152, 0, 0.8)'
                    }
                ]
            },
            options: {
                responsive: true,
                scales: {
                    x: { stacked: true },
                    y: { stacked: true, title: { display: true, text: 'Games' } }
                }
            }
        });
        
    } catch (error) {
        console.error('Error loading win/loss chart:', error);
        document.getElementById('winLossChart').parentElement.innerHTML = 
            '<p class="text-danger" style="text-align: center; padding: 2rem;">Error loading chart. Please refresh.</p>';
    }
}
```

#### Chart 2: Goal Differential Trend

```javascript
async function loadGoalDiffChart() {
    try {
        // Similar to loadStandingsTrendChart but show goal differential
        // This requires enhancing standings_history to include goals for/against
        
        const ctx = document.getElementById('goalDiffChart').getContext('2d');
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: dates,
                datasets: fanDatasets // goal_diff per fan over time
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        title: { text: 'Goal Differential' }
                    }
                }
            }
        });
    } catch (error) {
        console.error('Error loading goal diff chart:', error);
    }
}
```

---

### Step 4: Enhance Data Collection (1-2 hours)

You'll need to enhance `lib/standings_history_tracker.rb` to include more data:

```ruby
# lib/standings_history_tracker.rb
def capture_snapshot(standings_data)
  snapshot = {
    date: Date.today.to_s,
    standings: {},
    details: {}  # NEW: Add detailed stats
  }
  
  standings_data.each do |fan, team_data|
    snapshot[:standings][fan] = team_data[:points]
    
    # NEW: Capture additional stats
    snapshot[:details][fan] = {
      wins: team_data[:wins],
      losses: team_data[:losses],
      ot_losses: team_data[:ot_losses],
      goals_for: team_data[:goals_for],
      goals_against: team_data[:goals_against],
      goal_diff: team_data[:goals_for] - team_data[:goals_against],
      games_played: team_data[:games_played]
    }
  end
  
  snapshot
end
```

---

### Step 5: Call Charts on Trends Tab Load (15 minutes)

Update the tab switching function:

```javascript
function switchTab(tabName) {
    // ... existing code ...
    
    // Load charts when switching to trends tab
    if (tabName === 'trends' && !window.chartsLoaded) {
        loadStandingsTrendChart();
        loadWinLossChart();
        loadGoalDiffChart();
        // loadPPGChart();
        // loadDivisionRankChart();
        window.chartsLoaded = true;
    }
}
```

---

### Step 6: Test Locally (30 minutes)

```bash
# Generate new standings with enhanced data
ruby update_standings.rb

# Open _site/index.html in browser
open _site/index.html

# Check:
# - Charts load without errors
# - Data displays correctly
# - Mobile responsive
# - No console errors
```

---

### Step 7: Styling & Polish (1-2 hours)

Add responsive styles to `lib/styles.css`:

```css
/* Chart container styling */
.chart-container {
    position: relative;
    height: 400px;
    padding: 1.5rem;
    background: var(--color-canvas-default);
}

@media (max-width: 768px) {
    .chart-container {
        height: 300px;
        padding: 1rem;
    }
}

/* Chart loading state */
.chart-container.loading::after {
    content: "Loading chart...";
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    color: var(--color-fg-muted);
}
```

---

## ✅ Checklist Before Committing

- [ ] All 4 charts render without JavaScript errors
- [ ] Charts are responsive on mobile (< 768px)
- [ ] Empty states handled gracefully
- [ ] Loading states show before data loads
- [ ] Error states display helpful messages
- [ ] Colors match the site theme
- [ ] Charts update when data changes
- [ ] Performance is good (< 2 second load)
- [ ] Tested in Chrome, Firefox, Safari
- [ ] Code is commented and readable

---

## 🎯 Expected Outcome

After this implementation:
- ✅ 4 new chart visualizations
- ✅ Better data insights for users
- ✅ Increased time on site (+30% expected)
- ✅ More engaging Trends tab
- ✅ Foundation for future chart additions

**Time investment:** 8-12 hours total

**User value:** Significantly improved data storytelling

---

## 🐛 Troubleshooting

### Chart not showing?
- Check browser console for errors
- Verify `standings_history.json` has data
- Ensure Chart.js is loaded (check network tab)
- Check canvas element exists in DOM

### Data not updating?
- Run `ruby update_standings.rb` to regenerate
- Check GitHub Actions for errors
- Verify `StandingsHistoryTracker` is running

### Charts too slow?
- Limit history to last 30 days for performance
- Implement data sampling for large datasets
- Add loading indicators

---

## 📈 Measuring Success

Track these metrics before/after:

**Before:**
- Average time on Trends tab: ?
- Trends tab visit rate: ?
- Return visits: ?

**After (2 weeks):**
- Target: 2x time on Trends tab
- Target: 1.5x visit rate  
- Target: 1.3x return visits

Use Google Analytics or similar to track.

---

## 🚀 Next Steps

After completing this:

1. **Gather Feedback** - Ask users what they think
2. **Iterate** - Fix issues, add requested features
3. **Move to P0 Feature #2** - Game Predictions System
4. **Keep Shipping** - Small, incremental improvements

---

## 💡 Tips for Success

- **Start simple** - Get one chart working, then copy
- **Use existing code** - The standings trend chart is your template
- **Test incrementally** - Don't wait until all 4 charts are done
- **Ask for help** - GitHub Discussions if stuck
- **Celebrate wins** - This is a significant improvement!

---

## 📚 Additional Resources

- [Chart.js Documentation](https://www.chartjs.org/docs/latest/)
- [Chart.js Examples](https://www.chartjs.org/docs/latest/samples/)
- [Color Schemes](https://coolors.co/) - For chart color palettes
- [Responsive Charts](https://www.chartjs.org/docs/latest/configuration/responsive.html)

---

**Ready to start?** Open `lib/standings.html.erb` and let's build! 🚀📊

*Questions? Reference the full ROADMAP.md or open a GitHub Discussion.*
