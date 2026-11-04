# NHL Standings Tracker

A live NHL standings tracker with playoff status indicators, fan ownership tracking, and upcoming game information. This project provides a clean, responsive interface for tracking teams as they advance toward the NHL Finals.

## Features

- **Live NHL Standings**: Up-to-date standings directly from the NHL API
- **Playoff Status Indicators**: Visual indicators showing which teams have clinched, are contending, or are eliminated
- **Fan Ownership Tracking**: Highlight teams owned by fans in your league
- **Upcoming Games**: Shows each team's next opponent with game time in Pacific timezone
- **Home Screen App**: Can be added to iOS/Android home screens with proper icons
- **Responsive Design**: Works well on both desktop and mobile devices
- **API Validation**: Automatically detects NHL API changes to prevent breaking
- **Offseason Team Briefs**: Official club headlines, roster reports, and short publisher descriptions for each fan team, with dates and source links

### Offseason coverage

During the offseason, League leads with team briefings; the previous season's
results remain in a closed disclosure. Other statistical views explicitly label
historical data. NHL schedule boundaries determine the phase when available;
summer and prior-season standings provide a conservative fallback.

Each existing site refresh fetches the latest 100 stories per configured club
from NHL's public [Forge content feed](https://forge-dapi.d3.nhle.com/v2/content/en-us/stories?context.slug=teamid-21&$limit=25&$sort=contentDate:desc).
The four-story brief combines current reports and roster coverage since June 1,
leading with roster news. Descriptions are publisher metadata, not AI-generated
summaries. Transaction tags and headline keywords label **roster news**, not a
complete list of confirmed moves. Publication dates are kept separate from fetch
times; future-dated and out-of-window stories are excluded.

`lib/offseason_news.rb` configures the 13 pool teams, including Utah's context
`teamid-68` and `/utah/news/` URL. Forge is a public NHL-hosted endpoint, not a
documented stability guarantee. `data/offseason_news.json` retains the last good
snapshot per team; failures show an explicit cached/unavailable state and never
infer a move. The existing three-hour Pages workflow refreshes and persists this
cache alongside its existing data. No separate scheduled service is needed.

## Setup and Usage

### Prerequisites

- Ruby 3.4+ with Bundler 2.7.x
- Node.js 20+
- Basic knowledge of CSV for team mapping

### Installation

1. Clone this repository
2. Install dependencies:
    ```
    bundle install
    npm install
    ```

3. Edit `fan_team.csv` to map your fantasy league members to NHL teams:
   ```
   fan,team
   Alice,Bruins
   Bob,Maple Leafs
   ```

4. Build the site:
    ```
    npm run build
    ```

5. Open `_site/index.html` in your browser to view the standings

### Deployment

The simplest way to deploy is using GitHub Pages:

1. Push your changes to GitHub
2. Enable GitHub Pages on your repository
3. Set the build directory to `_site`

**Note:** The `_site/` directory is gitignored, but specific files required for deployment must be force-added with `git add -f`. If you add new static assets (CSS, JS, images) that need to be deployed, make sure to:
- Copy them to `_site/` via the build script
- Force-add them: `git add -f _site/your-file.css`
- Commit and push them

## Configuration

### Season data and playoff status

Head-to-head records and matchup goal differences use the NHL standings
`seasonId`, including seasons that open in September. Division and wildcard
labels describe current positions, not clinched berths. Teams are marked
eliminated only when the NHL reports `clinchIndicator: "e"`; other teams outside
playoff positions remain in the hunt.

The daily API monitor uses the repository's `.ruby-version` and checks the same
current playoff-bracket endpoint as the site. Dependency setup failures remain
workflow failures; only an executed API check failure opens an alert issue.

### Fan Team Mapping

The `fan_team.csv` file maps fan names to teams. The format is simple:
```
fan,team
Alice,Bruins
Bob,Maple Leafs
```

The "team" column can use full names, city names, or common nicknames - the system will attempt to match them to the correct NHL team.

## Development

### Project Structure

- `lib/` - Core library code
  - `standings_processor.rb` - Main data processing logic
  - `api_validator.rb` - NHL API validation
  - `team_mapping.rb` - Team name/abbreviation mapping
  - `standings.html.erb` - HTML template

- `spec/` - Tests
  - `fixtures/` - Test data

### Running Tests

```
npm run test:ruby
npm run test:e2e
```

`npm run test:e2e` now builds the static site before Playwright starts its local server, so end-to-end runs always exercise a fresh `_site/` output instead of whatever happened to be generated earlier.

Code coverage reports are automatically generated in the `coverage/` directory.

### GitHub Actions Workflows

This project includes several automated workflows:

- **PR Preview Deployment**: Automatically deploys pull request previews to isolated paths (`/pr-{number}/`) that don't interfere with the main deployment
- **Deployment Cleanup**: Scheduled daily job that removes old preview deployments (older than 30 days) and cleans up deployments for closed PRs
- **Manual Cleanup**: Deployment pruning can be triggered manually with custom retention periods via workflow dispatch

The preview environment system ensures that:
- Each PR gets its own isolated preview URL
- Main deployment remains undisturbed
- Old deployments are automatically cleaned up
- Manual override available for custom scenarios

## Product Roadmap

**Context:** This is a **private 13-person fan league**, not a public product. The roadmap focuses on keeping these specific fans engaged throughout the season.

**Infrastructure:** All features work with existing GitHub Pages + Actions. **No replatforming or external services required.** See [INFRASTRUCTURE.md](./INFRASTRUCTURE.md) for details.

Want to see what's next? Check out our improvement roadmap:

- **[INFRASTRUCTURE.md](./INFRASTRUCTURE.md)** - **Infrastructure Q&A:** No replatforming needed, all features use existing GitHub setup
- **[ROADMAP_CONTEXT.md](./ROADMAP_CONTEXT.md)** - Target audience, methodology, and projection rationale
- **[ROADMAP.md](./ROADMAP.md)** - Comprehensive roadmap with detailed implementation guides
- **[ROADMAP_EXECUTIVE_SUMMARY.md](./ROADMAP_EXECUTIVE_SUMMARY.md)** - TL;DR version with 90-day action plan
- **[ROADMAP_TRACKING.md](./ROADMAP_TRACKING.md)** - Track implementation progress as features are completed
- **[TASKS.md](./TASKS.md)** - **HIGH-IMPACT FOCUS:** Critical path & P0 tasks (17 high-impact tasks)

**Quick Overview:**
- 🔥 **P0 Priority:** Game predictions, enhanced charts, real-time updates
- ⭐ **P1 Priority:** Push notifications, player stats, league chat  
- 📌 **P2 Priority:** Advanced analytics, historical views, PWA enhancements

**For AI Agents:** Start with [TASKS.md](./TASKS.md) **Critical Path** section (3 tasks that unblock everything else).

See the roadmap for ROI analysis, implementation guides, and success metrics. Use the tracking document to monitor progress.

## License

[MIT License](LICENSE)
