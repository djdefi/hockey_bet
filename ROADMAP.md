# Hockey Bet - Product Roadmap

> **Last Updated:** November 21, 2025  
> **Next Review:** December 21, 2025

This roadmap outlines high-value improvements prioritized by impact and implementation effort.

---

## 🎯 Executive Summary

The Hockey Bet project is a well-built NHL fantasy league tracker with strong fundamentals:
- ✅ Solid Ruby architecture with good test coverage
- ✅ Automated data updates via GitHub Actions
- ✅ Responsive, accessible UI
- ✅ Real-time NHL API integration

**Key Opportunities:**
1. **User Engagement** - Add interactive betting/prediction features
2. **Data Insights** - Deeper analytics and visualizations
3. **Social Features** - League communication and competition
4. **Mobile Experience** - Enhanced PWA capabilities
5. **Performance** - Optimization and caching improvements

---

## 📊 Prioritization Matrix

| Priority | Feature | Value | Effort | Status |
|----------|---------|-------|--------|--------|
| 🔥 P0 | Game Predictions/Betting | High | Medium | Not Started |
| 🔥 P0 | Enhanced Trend Charts | High | Low | Not Started |
| ⭐ P1 | Notification System | High | Medium | Not Started |
| ⭐ P1 | League Chat/Comments | Medium | High | Not Started |
| ⭐ P1 | Player Stats Integration | High | High | Not Started |
| 📌 P2 | Advanced Analytics | Medium | Medium | Not Started |
| 📌 P2 | Historical Season View | Medium | Low | Not Started |
| 📌 P2 | Mobile App (PWA++) | Medium | High | Not Started |
| 💡 P3 | Custom Achievements | Low | Medium | Not Started |
| 💡 P3 | Export/Share Features | Low | Low | Not Started |

---

## 🔥 Priority 0 - High Value, Near-Term (1-2 months)

### 1. Game Predictions & Voting System 🎯

**Problem:** The site shows upcoming matchups but lacks interactivity. The voting placeholder says "Voting opens soon!" but isn't implemented.

**Solution:** Add a prediction/betting system where fans can:
- Vote on game outcomes before they start
- Earn bonus points for correct predictions
- See prediction accuracy stats
- View league-wide prediction trends

**Implementation:**
```ruby
# lib/prediction_tracker.rb
class PredictionTracker
  # Store predictions in data/predictions.json
  # Track accuracy per fan
  # Update after games complete
end
```

**Files to Create:**
- `lib/prediction_tracker.rb` - Core prediction logic
- `lib/prediction_processor.rb` - Process game results
- `spec/prediction_tracker_spec.rb` - Tests
- Update `lib/standings.html.erb` - Add voting UI
- Update GitHub Action to process predictions

**Value:**
- Increases user engagement 10x
- Creates reason to visit multiple times per day
- Adds competitive element beyond team performance

**Effort:** Medium (2-3 weeks)
- Backend: 40 hours
- Frontend: 20 hours  
- Testing: 15 hours

---

### 2. Enhanced Trend Visualizations 📈

**Problem:** Only one basic line chart exists. Rich historical data is collected but underutilized.

**Solution:** Add multiple chart views:
- **Win/Loss Trends** - Visualize W/L/OTL over time
- **Goal Differential Chart** - Track scoring trends
- **Division Rankings** - Show division position changes
- **Head-to-Head History** - Visual record against specific fans
- **Playoff Odds Over Time** - Track championship probability

**Implementation:**
```javascript
// New charts in standings.html.erb
function loadGoalDifferentialChart() { ... }
function loadDivisionRankingsChart() { ... }
function loadPlayoffOddsChart() { ... }
```

**Enhancements to Existing Chart:**
- Add zoom/pan controls
- Season markers (playoffs start, trade deadline)
- Export as image button
- Mobile-optimized touch interactions

**Value:**
- Better data storytelling
- Insights into team/fan performance
- Increases time on site

**Effort:** Low-Medium (1-2 weeks)
- 3-4 new chart implementations
- Use existing Chart.js setup
- Leverage existing `standings_history.json` data

---

### 3. Real-Time Score Updates ⚡

**Problem:** Updates only happen every 3 hours via GitHub Actions. Games in progress aren't tracked.

**Solution:** 
- Add live game tracker for in-progress games
- Show real-time scores for fan matchups
- Update points/standings live during games
- Add "🔴 LIVE" indicator for active games

**Implementation:**
```ruby
# lib/live_game_tracker.rb
class LiveGameTracker
  def fetch_live_scores
    # Poll NHL API live endpoint every 60 seconds
    # Update game states in real-time
  end
end
```

**Technical Approach:**
- Use NHL API's live game endpoint
- Add JavaScript polling (every 60 seconds during game windows)
- Store live data in `_site/live_games.json`
- Update UI without full page reload

**Value:**
- Dramatically improves engagement during games
- Makes site the "go-to" place during game nights
- Creates urgency and excitement

**Effort:** Medium (2-3 weeks)
- NHL API integration: 15 hours
- Frontend real-time updates: 20 hours
- Testing & optimization: 10 hours

---

## ⭐ Priority 1 - High Value, Medium-Term (2-4 months)

### 4. Push Notifications System 🔔

**Problem:** Users must remember to check the site for updates.

**Solution:** Implement web push notifications for:
- Game start reminders (your team plays in 1 hour)
- Game results (your team won!)
- Important events (clinched playoff spot, eliminated)
- Prediction reminders (vote before 7 PM!)
- Position changes (you moved up to 3rd place!)

**Implementation:**
- Use Web Push API
- Service worker for offline support
- Notification preferences page
- Backend service for push triggers

**Technologies:**
- Service Worker API
- Push API
- Notifications API
- Optional: Firebase Cloud Messaging for reliability

**Value:**
- Re-engages users automatically
- Increases daily active users
- Creates habit formation

**Effort:** Medium (3-4 weeks)

---

### 5. Player-Level Statistics 🏒

**Problem:** Only team-level stats are shown. Fans want to know about specific players.

**Solution:** Add player tracking:
- Top scorers for each fan's team
- Player performance trends
- Injury reports and impact analysis
- Fantasy-style player comparisons
- "Your Star Players" widget

**Implementation:**
```ruby
# lib/player_stats_tracker.rb
class PlayerStatsTracker
  def fetch_roster(team_id)
    # Get team roster
  end
  
  def fetch_player_stats(player_id)
    # Get goals, assists, points
  end
  
  def get_team_leaders(team_id)
    # Return top 3 players
  end
end
```

**New UI Components:**
- Player stats modal on team card click
- Top performers section
- Injury impact indicators

**Value:**
- Deeper engagement with teams
- Educational for casual fans
- Competitive intel on opponents

**Effort:** High (5-6 weeks)
- NHL Player API integration
- Data modeling
- UI components
- Performance optimization

---

### 6. League Chat & Activity Feed 💬

**Problem:** No way for league members to communicate or trash talk.

**Solution:** Add communication features:
- Simple comment system per game/matchup
- Activity feed showing recent events
- Emoji reactions to games
- @mention notifications

**Implementation Options:**
1. **Static Solution:** GitHub Issues/Discussions integration
2. **Hosted Solution:** Disqus or similar service
3. **Custom:** Simple Firebase/Supabase backend

**Recommended:** Start with GitHub Discussions integration (free, no backend needed)

**Value:**
- Builds community
- Increases engagement
- Encourages return visits

**Effort:** Medium-High (varies by approach)
- GitHub Discussions: 1 week
- Custom solution: 4-6 weeks

---

## 📌 Priority 2 - Medium Value, Medium-Term (3-6 months)

### 7. Advanced Analytics Dashboard 📊

**Features:**
- Power rankings algorithm
- Strength of schedule analysis
- Playoff probability calculator
- "What if" scenarios
- Performance against playoff teams
- Home vs Away splits
- Recent form (last 5/10 games)

**Value:** Appeals to stat nerds, adds depth
**Effort:** Medium (3-4 weeks)

---

### 8. Multi-Season Historical View 📅

**Problem:** Can't compare to previous seasons.

**Solution:**
- Archive previous season data
- Season comparison charts
- All-time leaderboards
- Season recap pages
- Draft history (if applicable)

**Value:** Long-term engagement, nostalgia
**Effort:** Low-Medium (2-3 weeks)

---

### 9. Enhanced PWA Features 📱

**Current:** Basic PWA with home screen install

**Improvements:**
- Offline mode with cached data
- Background sync when online
- Improved mobile navigation
- Swipe gestures
- Native app-like transitions
- Share to social media

**Value:** Better mobile experience
**Effort:** High (5-6 weeks)

---

### 10. Trade Analyzer & Proposals 🔄

**If your league allows trading:**
- Trade proposal system
- Trade analysis (fair/unfair)
- Historical trade review
- Trade deadline countdown

**Value:** Adds strategic element
**Effort:** High (6-8 weeks)

---

## 💡 Priority 3 - Nice-to-Have (6+ months)

### 11. Custom Achievement System 🏆

**Beyond current badges:**
- Season-long achievements
- Rare badges for special events
- Achievement progress tracking
- Collectible badge gallery
- Achievement notifications

**Value:** Gamification, collection
**Effort:** Medium (3-4 weeks)

---

### 12. Export & Sharing Features 📤

**Features:**
- Export standings as image
- Share matchup preview cards
- Generate season recap video/slides
- Email digest subscriptions
- Social media auto-posting

**Value:** Virality, engagement
**Effort:** Low-Medium (2-3 weeks)

---

### 13. AI-Powered Predictions 🤖

**Features:**
- ML model for game predictions
- Team performance forecasting
- Playoff probability models
- Recommendation engine for trades

**Value:** Cutting edge, media attention
**Effort:** Very High (8-12 weeks)

---

### 14. Multiple Leagues Support 👥

**Problem:** Currently single-league only

**Solution:**
- Support multiple independent leagues
- League admin panel
- Join/create league flow
- Public vs private leagues

**Value:** Scalability, wider audience
**Effort:** Very High (12+ weeks)

---

## 🔧 Technical Improvements

### Performance Optimization
- [ ] Add Redis/CDN caching layer
- [ ] Optimize image loading (lazy load logos)
- [ ] Minify CSS/JS
- [ ] Implement service worker caching
- [ ] Add performance monitoring

### Code Quality
- [ ] Add code coverage tracking
- [ ] Set up continuous integration
- [ ] Add Rubocop/linting to CI
- [ ] Performance profiling
- [ ] Security audit

### Infrastructure
- [ ] Add staging environment
- [ ] Set up error tracking (Sentry)
- [ ] Add analytics (privacy-focused)
- [ ] Database for user data (when needed)
- [ ] API rate limiting

---

## 🎨 UI/UX Enhancements

### Design Improvements
- [ ] Dark/light mode toggle
- [ ] Customizable color themes
- [ ] Accessibility audit (WCAG 2.1 AA)
- [ ] Loading states and skeletons
- [ ] Better mobile navigation
- [ ] Animations and transitions
- [ ] Empty states with helpful CTAs

### User Experience
- [ ] Onboarding flow for new users
- [ ] Help/FAQ section
- [ ] Keyboard shortcuts
- [ ] Search functionality
- [ ] Filtering and sorting options
- [ ] Persistent user preferences

---

## 📱 Mobile App Considerations

### Progressive Web App (PWA) Roadmap
1. **Phase 1:** Enhanced offline support (3 weeks)
2. **Phase 2:** Push notifications (4 weeks)
3. **Phase 3:** Native features (camera, sharing) (4 weeks)
4. **Phase 4:** App store submission (2 weeks)

### Native App (Long-term)
- React Native or Flutter consideration
- If user base grows significantly (1000+ active users)
- Estimated effort: 6+ months
- Cost: $50-100k with agency or $0 if DIY

---

## 🚀 Quick Wins (1-2 weeks each)

Fast improvements for immediate impact:

1. **Search/Filter Bar** - Find teams/fans quickly
2. **Keyboard Shortcuts** - Power user features
3. **Printable Standings** - Print-friendly CSS
4. **Season Stats Summary** - One-page overview
5. **Better Mobile Navigation** - Bottom nav bar
6. **Loading Indicators** - Better perceived performance
7. **Color-coded Streaks** - Visual win/loss patterns
8. **Playoff Scenarios** - "Magic numbers" to clinch
9. **Social Share Cards** - Open Graph meta tags
10. **Favicon Improvements** - Animated favicon for live games

---

## 📈 Success Metrics

Track these KPIs to measure improvements:

### Engagement Metrics
- Daily Active Users (DAU)
- Time on site
- Pages per session
- Return visit rate
- Feature adoption rate

### Performance Metrics
- Page load time (< 2 seconds)
- Time to interactive (< 3 seconds)
- Core Web Vitals scores
- Error rate (< 0.1%)

### Business Metrics
- User growth rate
- User retention (weekly)
- Feature usage stats
- User satisfaction (surveys)

---

## 🎯 Recommended Starting Point

**For Immediate Impact (Next 30 Days):**

1. **Week 1-2:** Enhanced Trend Charts
   - Low effort, high value
   - Leverages existing data
   - Improves data storytelling

2. **Week 3-4:** Game Predictions MVP
   - Start with simple voting
   - Core engagement feature
   - Can iterate based on feedback

3. **Week 5+:** Real-time Score Updates
   - Game-changing feature
   - High engagement during games
   - Builds on prediction system

**Why this order?**
- Quick wins build momentum
- Each feature builds on previous
- Validates user interest before major investment
- Allows for user feedback and iteration

---

## 🤝 Implementation Strategy

### Development Process
1. **Plan** - Review roadmap, prioritize next feature
2. **Design** - Create mockups, get feedback
3. **Build** - Implement with tests
4. **Review** - Code review, QA testing
5. **Deploy** - Staged rollout
6. **Monitor** - Track metrics, gather feedback
7. **Iterate** - Refine based on data

### Resource Allocation
- **Solo Developer:** Focus on P0 items, 1 feature at a time
- **Small Team (2-3):** Parallel workstreams, P0 + P1 simultaneously
- **Larger Team (4+):** Multiple priorities, technical debt alongside features

### Release Cadence
- **Sprint Length:** 2 weeks
- **Release Frequency:** Every sprint
- **Hotfixes:** As needed
- **Major Features:** Feature flags for gradual rollout

---

## 📚 Resources & References

### APIs & Data Sources
- [NHL API Documentation](https://gitlab.com/dword4/nhlapi)
- [Chart.js Documentation](https://www.chartjs.org/docs/latest/)
- [Web Push Protocol](https://web.dev/push-notifications-overview/)

### Design Inspiration
- ESPN Fantasy
- Yahoo Sports
- The Athletic
- FanDuel / DraftKings

### Technical References
- [PWA Checklist](https://web.dev/pwa-checklist/)
- [Web.dev Performance](https://web.dev/performance/)
- [WCAG Accessibility Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

---

## 🔄 Roadmap Review Schedule

This roadmap should be reviewed and updated:
- **Monthly:** Adjust priorities based on user feedback
- **Quarterly:** Major strategic review
- **Annually:** Long-term vision alignment

**Next Review Date:** December 21, 2025

---

## 📊 Implementation Tracking

As features are implemented, track progress in **[ROADMAP_TRACKING.md](./ROADMAP_TRACKING.md)**. This document provides:
- Checkboxes for each feature and subtask
- Status indicators (Not Started, In Progress, Completed)
- Branch and PR links
- Metrics tracking (baseline and results)
- Completion dates

**Update the tracking document as you work to maintain visibility on progress.**

---

## 💬 Feedback & Contributions

This roadmap is a living document. Suggestions welcome!

- Open an issue for feature requests
- Comment on existing items with feedback
- Submit PRs for documentation improvements

---

## Appendix A: Technical Architecture Improvements

### Current Architecture
```
GitHub Actions (every 3h)
    ↓
Ruby Scripts (fetch NHL data)
    ↓
Process & Generate HTML
    ↓
Static Site (_site/)
    ↓
GitHub Pages (deploy)
```

### Proposed Architecture (Future)
```
GitHub Actions + Real-time Workers
    ↓
Ruby Backend + Cache Layer
    ↓
API Layer (JSON endpoints)
    ↓
Modern Frontend (React/Vue)
    ↓
CDN + Edge Functions
```

### Migration Path
1. Keep static generation for core content
2. Add JSON API endpoints for dynamic data
3. Introduce JavaScript framework incrementally
4. Add backend services as needed
5. Full migration only if user base warrants it

---

## Appendix B: Feature Specifications

Each P0/P1 feature should have a detailed spec before implementation. Template:

```markdown
## Feature: [Name]

**Overview:** Brief description

**User Stories:**
- As a [user type], I want [goal] so that [benefit]

**Acceptance Criteria:**
- [ ] Criteria 1
- [ ] Criteria 2

**Technical Design:**
- Architecture diagram
- Data models
- API contracts

**Testing Plan:**
- Unit tests
- Integration tests
- User acceptance tests

**Rollout Plan:**
- Feature flag configuration
- Phased rollout %
- Rollback plan

**Success Metrics:**
- Metric 1: Target value
- Metric 2: Target value
```

---

## Appendix C: Estimated Timeline

**Aggressive (Full-time, dedicated):**
- P0 Features: 2-3 months
- P1 Features: 3-4 months  
- P2 Features: 4-6 months
- **Total:** 9-13 months

**Moderate (Part-time, 10-15 hrs/week):**
- P0 Features: 4-6 months
- P1 Features: 6-9 months
- P2 Features: 9-12 months
- **Total:** 19-27 months

**Realistic (Side project, 5-10 hrs/week):**
- P0 Features: 6-9 months
- P1 Features: 9-15 months
- P2 Features: 15-24 months
- **Total:** 30-48 months

**Recommendation:** Focus on P0 only in Year 1, validate with users, then decide on P1/P2.

---

*This roadmap was created through comprehensive analysis of the codebase, current features, and industry best practices for sports tracking applications.*
