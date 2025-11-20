# Fan League Standings Trend Chart - Setup Guide

## Overview
The standings trend chart visualizes how fan points have changed over time throughout the NHL season using Chart.js.

## Chart Features
- **Line chart** showing each fan's points over time
- **Team colors**: Each fan's line uses their NHL team's official brand color
- **Interactive tooltips**: Hover over data points to see exact date and points
- **Responsive design**: Adapts to mobile and desktop screens
- **Dark mode compatible**: Works with the site's theme

## Data Structure

The chart reads from two JSON files:

### 1. `_site/standings_history.json`
```json
[
  {
    "date": "2024-10-10",
    "standings": {
      "Jeff C.": 10,
      "Travis R.": 8,
      ...
    }
  }
]
```

### 2. `_site/fan_team_colors.json`
```json
{
  "Jeff C.": "#6F263D",
  "Brian D.": "#006D75",
  ...
}
```

## Backfilling Historical Data

Since the chart was added mid-season, you may want to backfill historical data.

### Option 1: Let it accumulate naturally
The GitHub Action runs every 3 hours and will gradually build up history. After a few weeks, you'll have good trend data.

### Option 2: Manual backfill (requires historical game data)
The `backfill_standings_history.rb` script provides a template, but you'll need to:

1. Access historical NHL standings data for specific dates
2. Calculate points for each team on those dates
3. Map to fans and add to history file

**Note**: The NHL API doesn't provide easy historical by-date lookups. You would need to:
- Fetch game logs for each team
- Calculate cumulative points for specific dates
- Build the standings snapshots

### Simpler approach for backfill:
If you have snapshots of the standings page from different dates saved, you can manually create history entries:

```bash
# Add an entry to standings_history.json
cat >> _site/standings_history.json << 'JSON'
{
  "date": "2024-10-15",
  "standings": {
    "Jeff C.": 12,
    "Travis R.": 10,
    ...
  }
}
JSON
```

Then commit the file:
```bash
git add _site/standings_history.json
git commit -m "Backfill standings history for 2024-10-15"
git push
```

## How It Works

1. **Data Collection**: `StandingsHistoryTracker` runs automatically via the update script
2. **Storage**: Data saved to `_site/standings_history.json` (365-day rolling window)
3. **GitHub Action**: Commits the file back to the repo every 3 hours
4. **Frontend**: JavaScript fetches both JSON files and renders the chart

## Viewing the Chart

Once you have at least 2 data points in `standings_history.json`, the chart will display automatically on the main page, positioned above the standings table.

## Troubleshooting

### Chart not showing?
- Check browser console for JavaScript errors
- Verify `standings_history.json` and `fan_team_colors.json` exist
- Ensure Chart.js CDN is not blocked by ad blockers
- Verify at least 2 historical data points exist

### Colors not matching teams?
- Check `lib/team_colors.rb` for correct color mappings
- Verify fan names match exactly in both files

### Data not updating?
- Check GitHub Actions logs for workflow run status
- Verify the workflow has `contents: write` permission
- Ensure commit step in workflow is executing

## Future Enhancements

Potential improvements:
- Zoom/pan controls for longer time ranges
- Export chart as image
- Show season start/playoffs markers
- Add trend lines or projections
- Multiple season comparison view
