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
