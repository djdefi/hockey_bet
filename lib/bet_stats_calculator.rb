# filepath: /home/runner/work/hockey_bet/hockey_bet/lib/bet_stats_calculator.rb
require 'csv'

class BetStatsCalculator
  attr_reader :stats

  def initialize(teams, manager_team_map, next_games)
    @teams = teams
    @manager_team_map = manager_team_map
    @next_games = next_games
    @stats = {}
  end

  # Calculate all bet stats
  def calculate_all_stats
    @stats = {
      top_winners: calculate_top_winners,
      top_losers: calculate_top_losers,
      upcoming_fan_matchups: calculate_upcoming_fan_matchups,
      longest_win_streak: calculate_longest_win_streak,
      longest_lose_streak: calculate_longest_lose_streak,
      rivalry_of_the_week: calculate_rivalry_of_the_week,
      best_point_differential: calculate_best_point_differential,
      biggest_underdog: calculate_biggest_underdog,
      best_playoff_position: calculate_best_playoff_position,
      worst_playoff_position: calculate_worst_playoff_position
    }
  end

  # Get teams owned by fans (excluding "N/A")
  def fan_teams
    @fan_teams ||= @teams.select do |team|
      abbrev = team['teamAbbrev']['default']
      @manager_team_map[abbrev] && @manager_team_map[abbrev] != "N/A"
    end
  end

  # Calculate top 3 fans with most wins
  def calculate_top_winners
    fan_teams
      .map { |team| create_fan_stat(team, team['wins'] || 0) }
      .sort_by { |stat| -stat[:value] }
      .take(3)
  end

  # Calculate top 3 fans with most losses
  def calculate_top_losers
    fan_teams
      .map { |team| create_fan_stat(team, team['losses'] || 0) }
      .sort_by { |stat| -stat[:value] }
      .take(3)
  end

  # Find most interesting upcoming fan vs fan matchups
  def calculate_upcoming_fan_matchups
    matchups = []
    
    @next_games.each do |team_id, game|
      next unless game && game['isFanTeamOpponent']
      
      # Get both teams
      home_abbrev = game['homeTeam']['abbrev']
      away_abbrev = game['awayTeam']['abbrev']
      
      home_team = find_team_by_abbrev(home_abbrev)
      away_team = find_team_by_abbrev(away_abbrev)
      
      next unless home_team && away_team
      
      home_fan = @manager_team_map[home_abbrev]
      away_fan = @manager_team_map[away_abbrev]
      
      # Skip if either fan is N/A
      next if home_fan == 'N/A' || away_fan == 'N/A'
      
      # Skip if already added (avoid duplicates)
      next if matchups.any? { |m| 
        (m[:home_fan] == home_fan && m[:away_fan] == away_fan) ||
        (m[:home_fan] == away_fan && m[:away_fan] == home_fan)
      }
      
      # Calculate "interest score" based on team standings
      home_points = home_team['points'] || 0
      away_points = away_team['points'] || 0
      point_diff = (home_points - away_points).abs
      
      # More interesting if teams are closer in points
      interest_score = 100 - point_diff
      
      matchups << {
        home_fan: home_fan,
        away_fan: away_fan,
        home_team: home_team['teamName']['default'],
        away_team: away_team['teamName']['default'],
        home_wins: home_team['wins'] || 0,
        away_wins: away_team['wins'] || 0,
        home_points: home_points,
        away_points: away_points,
        interest_score: interest_score,
        game_time: game['startTimeUTC']
      }
    end
    
    matchups.sort_by { |m| -m[:interest_score] }.take(3)
  end

  # Calculate fan with longest winning streak
  def calculate_longest_win_streak
    fan_teams
      .select { |team| team['streakCode'] && team['streakCode'].start_with?('W') }
      .map { |team| create_streak_stat(team) }
      .max_by { |stat| stat[:value] }
  end

  # Calculate fan with longest losing streak
  def calculate_longest_lose_streak
    fan_teams
      .select { |team| team['streakCode'] && team['streakCode'].start_with?('L') }
      .map { |team| create_streak_stat(team) }
      .max_by { |stat| stat[:value] }
  end

  # Calculate rivalry of the week (most interesting upcoming fan matchup based on point differential)
  def calculate_rivalry_of_the_week
    matchups = calculate_upcoming_fan_matchups
    matchups.first
  end

  # Calculate fan with best goal differential
  def calculate_best_point_differential
    fan_teams
      .map do |team|
        games_played = (team['wins'] || 0) + (team['losses'] || 0) + (team['otLosses'] || 0)
        next nil if games_played == 0
        
        # goalsForPctg and goalAgainst are already per-game values
        goals_for_per_game = team['goalsForPctg'] || 0
        goals_against_per_game = team['goalAgainst'] || 0
        differential_per_game = goals_for_per_game - goals_against_per_game
        
        abbrev = team['teamAbbrev']['default']
        # Format with + for positive values, clean up trailing zeros
        formatted_value = differential_per_game.round(2)
        display_value = formatted_value >= 0 ? "+#{formatted_value}" : formatted_value.to_s
        
        {
          fan: @manager_team_map[abbrev],
          team: team['teamName']['default'],
          value: formatted_value,
          display: "#{display_value} goals/game"
        }
      end
      .compact
      .max_by { |stat| stat[:value] }
  end

  # Calculate biggest underdog (lowest ranked fan team still in playoff contention)
  def calculate_biggest_underdog
    fan_teams
      .select { |team| team['wildcardSequence'].to_i > 0 && team['wildcardSequence'].to_i <= 2 }
      .map { |team| create_fan_stat(team, team['leagueSequence'] || 0, suffix: " in league") }
      .max_by { |stat| stat[:value] }
  end

  # Calculate best playoff position
  def calculate_best_playoff_position
    fan_teams
      .map { |team| create_fan_stat(team, team['leagueSequence'] || 999) }
      .min_by { |stat| stat[:value] }
  end

  # Calculate worst playoff position
  def calculate_worst_playoff_position
    fan_teams
      .map { |team| create_fan_stat(team, team['leagueSequence'] || 999) }
      .max_by { |stat| stat[:value] }
  end

  private

  # Helper to create a stat hash for a fan/team
  def create_fan_stat(team, value, suffix: "")
    abbrev = team['teamAbbrev']['default']
    {
      fan: @manager_team_map[abbrev],
      team: team['teamName']['default'],
      value: value,
      display: "#{value}#{suffix}"
    }
  end

  # Helper to create a streak stat
  def create_streak_stat(team)
    abbrev = team['teamAbbrev']['default']
    streak_code = team['streakCode']
    streak_num = streak_code.gsub(/[^\d]/, '').to_i
    
    {
      fan: @manager_team_map[abbrev],
      team: team['teamName']['default'],
      value: streak_num,
      display: streak_code
    }
  end

  # Helper to find team by abbreviation
  def find_team_by_abbrev(abbrev)
    @teams.find { |t| t['teamAbbrev']['default'] == abbrev }
  end
end
