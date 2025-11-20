# Fan League Standings Trend Chart - Visual Guide

## Chart Location
The chart appears on the main page, positioned **immediately above the NHL Team Standings table**.

```
┌─────────────────────────────────────────────────────────────┐
│  🏆 Fan League Stats & Bragging Rights 🏆                   │
│  [Various stats cards: Cup Odds, Winners, Losses, etc.]     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  📈 Fan League Standings Trend 📈                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                                                     │   │
│  │  30 ┼                                    ╭──Jeff C.│   │
│  │     │                              ╭────╯          │   │
│  │  25 ┼                        ╭────╯               │   │
│  │     │                  ╭────╯  ╭──Travis R.       │   │
│  │  20 ┼            ╭────╯  ╭───╯                    │   │
│  │     │      ╭────╯  ╭────╯                          │   │
│  │  15 ┼╭────╯  ╭───╯                                 │   │
│  │     ││  ╭───╯                                      │   │
│  │  10 ┼╯╭╯                                           │   │
│  │     ││                                             │   │
│  │   5 ┼╯                                             │   │
│  │     │                                              │   │
│  │     └────────────────────────────────────────────►│   │
│  │    Oct 10  Oct 20  Nov 1   Nov 10  Nov 20        │   │
│  │                                                     │   │
│  │  Legend: — Jeff C. (Burgundy)  — Travis R. (Red) │   │
│  │          — Keith R. (Orange)   — Brian D. (Teal) │   │
│  │          [All 13 fans shown in team colors]       │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  Team          | Fan      | Status | W | L | OTL | Pts    │
│  ──────────────┼──────────┼────────┼───┼───┼─────┼────────│
│  Avalanche     | Jeff C.  | ✓      | 13| 1 | 5   | 31     │
│  Devils        | Travis R.| ✓      | 13| 5 | 1   | 27     │
│  ...                                                        │
└─────────────────────────────────────────────────────────────┘
```

## Chart Features

### Visual Elements
- **Line Chart**: Each fan represented by a colored line
- **Team Colors**: Lines use official NHL team brand colors
  - Jeff C. (Avalanche): Burgundy #6F263D
  - Brian D. (Sharks): Teal #006D75
  - Keith R. (Ducks): Orange #F47A38
  - Travis R. (Devils): Red #CE1126
  - And all other fans in their team colors

### Interactive Features
- **Hover tooltips**: Shows exact date and points when hovering over data points
- **Legend**: Click to show/hide specific fans
- **Responsive**: Adapts height and layout for mobile devices

### Data Timeline
- **X-axis**: Dates from season start to present
- **Y-axis**: Points (0 to ~35+ range)
- **Data points**: One per date in history file

## Example Chart Output

With the sample data (5 historical snapshots), the chart shows:
- Jeff C. leading with steady growth from 10 → 31 points
- Travis R. and Keith R. closely competing at 27 points
- Clear separation between top performers and struggling teams
- Visual trends showing momentum shifts over time

## Chart Will Display When:
✅ At least 2 data points exist in `standings_history.json`  
✅ `fan_team_colors.json` is present with color mappings  
✅ Chart.js CDN loads successfully (not blocked by ad blockers)  
✅ Page is loaded with JavaScript enabled
