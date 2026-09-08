require_relative '../lib/standings_processor'
require_relative '../lib/playoff_processor'

# Render production templates with deterministic test data; never publish fixtures.
teams = JSON.parse(File.read('spec/fixtures/teams.json')).fetch('standings')
manager_team_map = { 'BOS' => 'Alice', 'MTL' => 'Bob', 'TOR' => 'Charlie' }
last_updated = '2025-04-09T12:00:00-07:00'
season_context = SeasonContext.new(teams: teams, today: Date.new(2025, 4, 9))

case ARGV.fetch(0)
when 'matchups', 'offseason', 'offseason-failure'
  game = JSON.parse(File.read('spec/fixtures/schedule.json')).fetch('gameWeek').first.fetch('games').first
  game['isFanTeamOpponent'] = true
  next_games = { 'BOS' => game, 'MTL' => game }
  calculator = BetStatsCalculator.new(teams, manager_team_map, next_games)
  calculator.calculate_stanley_cup_odds
  bet_stats = {
    best_cup_odds: calculator.calculate_best_cup_odds,
    upcoming_fan_matchups: calculator.calculate_upcoming_fan_matchups,
    playoff_progression: calculator.playoff_progression
  }
  if ARGV[0].start_with?('offseason')
    season_context = SeasonContext.new(teams: [{ 'seasonId' => 20252026 }], today: Date.new(2026, 9, 7))
    offseason_report = %w[BOS MTL].map do |abbrev|
      team = teams.find { |entry| entry['teamAbbrev']['default'] == abbrev }
      {
        'abbrev' => abbrev, 'team' => team['teamName']['default'], 'fan' => manager_team_map[abbrev],
        'news_url' => "https://www.nhl.com/#{abbrev == 'BOS' ? 'bruins' : 'canadiens'}/news",
        'updated_at' => '2026-09-06T12:00:00Z', 'status' => 'fresh',
        'articles' => [{
          'title' => "Test fixture: #{abbrev} signs a player",
          'url' => "https://www.nhl.com/news/test-fixture-#{abbrev.downcase}",
          'published_at' => '2026-09-05T16:00:00Z', 'roster_news' => true,
          'summary' => 'Fixture publisher brief: a roster announcement for browser testing.'
        }]
      }
    end
    if ARGV[0] == 'offseason-failure'
      offseason_report[0]['status'] = 'cached'
      offseason_report[1].merge!('status' => 'unavailable', 'updated_at' => nil, 'articles' => [])
    end
  end
  puts ERB.new(File.read('lib/standings.html.erb')).result(binding)
when 'playoffs'
  @is_playoff_time = true
  @manager_team_map = manager_team_map
  @last_updated = last_updated
  pr_preview = false
  pr_number = nil
  contenders = %w[BOS MTL TOR].map do |abbrev|
    team = teams.find { |entry| entry['teamAbbrev']['default'] == abbrev }
    { abbrev: abbrev, name: team['teamName']['default'], logo: get_team_logo_url(abbrev), seed: 'D1' }
  end
  tbd = { abbrev: 'TBD', name: 'TBD' }
  @playoff_rounds = [
    { round_key: 'R1', name: 'First Round', series: [
      { home_team: contenders[0], away_team: contenders[1], home_wins: 2, away_wins: 1, status: 'BOS leads 2-1' },
      { home_team: contenders[2], away_team: contenders[1], home_wins: 4, away_wins: 2,
        winner_abbrev: 'TOR', eliminated_abbrev: 'MTL', status: 'TOR wins 4-2' }
    ] },
    { round_key: 'SCF', name: 'Stanley Cup Final', series: [
      { home_team: tbd, away_team: tbd, home_wins: 0, away_wins: 0, is_tbd: true }
    ] }
  ]
  @fan_cup_odds = { 'Alice' => 24.0, 'Charlie' => 18.0, 'Bob' => 0.0 }
  @fan_status = contenders.to_h do |team|
    fan = manager_team_map.fetch(team[:abbrev])
    [fan, { primary_team: team, cup_odds: @fan_cup_odds.fetch(fan),
            status: fan == 'Bob' ? :eliminated : :alive, tagline: team[:name] }]
  end
  puts ERB.new(File.read('lib/playoffs.html.erb')).result(binding)
else
  abort 'Unknown graphics fixture'
end
