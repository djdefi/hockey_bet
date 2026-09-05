# NHL Fan League

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Members of an existing NHL fan pool checking their assigned teams, the league
race, upcoming matchups, and playoff prospects on desktop and mobile.

## Product Purpose

Make it easy to follow the fan pool throughout the NHL season: see who is
leading, compare teams, and follow the games that affect the pool.

## Capabilities and Constraints

- Ruby renders a static site deployed to GitHub Pages.
- The main views are League, Matchups, Standings, Playoff Odds, and Trends.
  A separate playoff page provides the bracket and fan playoff status.
- NHL API data supplies standings and schedules. Existing processors calculate
  pool statistics and predictions.
- Preserve team assignments, calculations, predictions, voting, and existing
  navigation behavior. The season refresh is a visual revamp, not a rules or
  data reset.
- Preserve team selection, local preferences, keyboard access, and the
  installable mobile-web experience.
- Do not invent season results, live status, odds, or upcoming games. Empty
  and offseason states must describe the available data accurately.

## Brand Commitments

- Keep the NHL Fan League name and existing team identities.
- The requested direction is fresh and clean for the coming season.
- The user selected Broadcast Viewfinder: a dark viewing field, white
  readouts, and amber focus cues. This replaces the incumbent broadcast look.

## Evidence on Hand

- `README.md`: product capabilities and build/deployment workflow.
- `fan_team.csv`: existing fan-to-team assignments.
- `lib/standings.html.erb` and `lib/playoffs.html.erb`: current interfaces.
- `lib/standings_processor.rb` and related processors: data and calculations.
- `spec/`, `tests/`, and `e2e/`: behavior and accessibility coverage.

## Product Principles

- Put the fan pool and its real NHL data before decorative content.
- Make scores, rankings, and status easy to compare.
- Keep the same tasks available across desktop and mobile.
- Preserve the pool's behavior while replacing the visual presentation.
