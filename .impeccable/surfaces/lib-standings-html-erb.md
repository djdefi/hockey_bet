---
version: 1
slug: "lib-standings-html-erb"
primary_target: "lib/standings.html.erb"
related_targets: ["lib/playoffs.html.erb","service-worker.js"]
---

# Season surfaces

- **Mode:** Operate.
- **Scope:** League, Matchups, Standings, Playoff Odds, and Trends in `lib/standings.html.erb`; separate bracket and fan playoff status in `lib/playoffs.html.erb`; the self-contained offline fallback in `service-worker.js`.
- **Member job:** Follow assigned teams, compare the pool race, and find meaningful upcoming games.
- **Navigation:** Start with the leader/chaser field, then move through the view rail to teams, matchups, odds, or trends; standings expand to in-place details. Mobile stacks the same reading order. Playoffs has return navigation, a framed heading, fan status, odds, and round-by-round series.
- **Selected world:** Broadcast Viewfinder, user-selected challenger, seed `5e1fc3ac`: neutral dark field, white readouts, amber focus brackets, system sans identity, and tabular monospaced measurements. The emitted five-part contracts in both templates record this choice; `DESIGN.md` owns global tokens and rules.
- **Constraints:** Use real NHL API data and existing processors; never fabricate season results, games, odds, or live status. Preserve assignments, calculations, predictions, voting, navigation, team themes, saved preferences, keyboard access, reduced-motion support, and mobile-web behavior. No generated comp or imagery was available or promised.
- **Offline and rollout:** Keep the fallback usable without external assets. Rotate both service-worker cache versions when replacing the shell; preserve local preferences and catch offline update failures.
- **Direction decisions:** None unresolved. The visual replacement is complete; pool behavior remains unchanged.
- **Graphics amplification:** Keep the selected world across all six views. The leader gets a larger focus-ring crest; featured and ordinary matchups use opposing crests over authored center ice. Standings and odds keep comparison-first rows with larger or newly added crests. Trends gets puck-trail artwork and a corner-framed plot without fabricated data. Playoffs carries the local Cup, larger podium and series crests, round-key readouts, and explicit TBD/offseason graphics.
- **Delivery and motion:** SVG symbols are inlined in both pages; shared graphic and offseason CSS are copied and precached through `lib/app-assets.json`. Cache version 14 delivers the offseason shell. A finite 300–500ms focus-lock is enabled only without reduced-motion preferences. Team names and abbreviation fallbacks remain available when external graphics fail.
- **Offseason content:** The League view leads with official-source team briefings, not the completed-season leader. A native team selector filters open, rule-separated briefings with team crests, fan assignments, publication dates, and source links. Historical results sit in a closed disclosure; standings, matchup comparisons, odds, and trends explicitly identify historical data. The dark field and amber focus remain unchanged.
- **Editorial boundary:** Publisher briefs and dated headlines are source material, not generated predictions or an exhaustive transaction database. Never infer a move from missing coverage. Automatic fetching is provisional pending user feedback; use the existing refresh workflow only.
