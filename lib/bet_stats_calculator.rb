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
    # Fetch head-to-head data first (needed for some stats)
    fetch_head_to_head_records
    
    @stats = {
      top_winners: calculate_top_winners,
      top_losers: calculate_top_losers,
      upcoming_fan_matchups: calculate_upcoming_fan_matchups,
      longest_win_streak: calculate_longest_win_streak,
      longest_lose_streak: calculate_longest_lose_streak,
      best_point_differential: calculate_best_point_differential,
      most_dominant: calculate_most_dominant,
      brick_wall: calculate_brick_wall,
      glass_cannon: calculate_glass_cannon,
      comeback_kid: calculate_comeback_kid,
      overtimer: calculate_overtimer,
      point_scrounger: calculate_point_scrounger,
      head_to_head_matrix: @head_to_head_matrix,
      fan_crusher: calculate_fan_crusher,
      fan_fodder: calculate_fan_fodder
    }
  end

  # Get teams owned by fans (excluding "N/A")
  def fan_teams
    @fan_teams ||= @teams.select do |team|
      abbrev = team['teamAbbrev']['default']
      @manager_team_map[abbrev] && @manager_team_map[abbrev] != "N/A"
    end
  end

  # Calculate top 3 fans with most wins (handles ties at 3rd place only)
  def calculate_top_winners
    all_stats = fan_teams
      .map { |team| create_fan_stat(team, team['wins'] || 0) }
      .sort_by { |stat| -stat[:value] }
    
    return [] if all_stats.empty?
    
    # Get top 3 positions, showing all teams tied at 3rd place
    # This ensures we show at most: 1st place team(s), 2nd place team(s), and 3rd place team(s)
    # but not 4th place even if only 3 unique values exist
    result = []
    unique_values = all_stats.map { |s| s[:value] }.uniq
    
    # Add teams at each of the top 3 positions
    unique_values.take(3).each do |value|
      result += all_stats.select { |s| s[:value] == value }
    end
    
    result
  end

  # Calculate top 3 fans with most losses (handles ties at 3rd place only)
  def calculate_top_losers
    all_stats = fan_teams
      .map { |team| create_fan_stat(team, team['losses'] || 0) }
      .sort_by { |stat| -stat[:value] }
    
    return [] if all_stats.empty?
    
    # Get top 3 positions, showing all teams tied at 3rd place
    # This ensures we show at most: 1st place team(s), 2nd place team(s), and 3rd place team(s)
    # but not 4th place even if only 3 unique values exist
    result = []
    unique_values = all_stats.map { |s| s[:value] }.uniq
    
    # Add teams at each of the top 3 positions
    unique_values.take(3).each do |value|
      result += all_stats.select { |s| s[:value] == value }
    end
    
    result
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
      
      # Calculate "interest score" based on team standings points (not goals)
      home_points = home_team['points'] || 0
      away_points = away_team['points'] || 0
      point_diff = (home_points - away_points).abs
      
      # More interesting if teams are closer in standings points
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

  # Calculate fan with longest winning streak (handles ties)
  def calculate_longest_win_streak
    all_streaks = fan_teams
      .select { |team| team['streakCode'] && team['streakCode'].start_with?('W') }
      .map { |team| create_streak_stat(team) }
    
    return nil if all_streaks.empty?
    
    max_value = all_streaks.map { |s| s[:value] }.max
    # Return all teams with the max streak value (handles ties)
    all_streaks.select { |s| s[:value] == max_value }
  end

  # Calculate fan with longest losing streak (handles ties)
  def calculate_longest_lose_streak
    all_streaks = fan_teams
      .select { |team| team['streakCode'] && team['streakCode'].start_with?('L') }
      .map { |team| create_streak_stat(team) }
    
    return nil if all_streaks.empty?
    
    max_value = all_streaks.map { |s| s[:value] }.max
    # Return all teams with the max streak value (handles ties)
    all_streaks.select { |s| s[:value] == max_value }
  end

  # Calculate fan with best goal differential (handles ties)
  def calculate_best_point_differential
    all_stats = fan_teams
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
    
    return nil if all_stats.empty?
    
    max_value = all_stats.map { |s| s[:value] }.max
    all_stats.select { |s| s[:value] == max_value }
  end

  # Calculate most dominant (best win percentage, handles ties)
  def calculate_most_dominant
    all_stats = fan_teams
      .map do |team|
        games_played = (team['wins'] || 0) + (team['losses'] || 0) + (team['otLosses'] || 0)
        next nil if games_played == 0
        
        wins = team['wins'] || 0
        win_pct = (wins.to_f / games_played * 100).round(1)
        
        abbrev = team['teamAbbrev']['default']
        {
          fan: @manager_team_map[abbrev],
          team: team['teamName']['default'],
          value: win_pct,
          display: "#{win_pct}% win rate"
        }
      end
      .compact
    
    return nil if all_stats.empty?
    
    max_value = all_stats.map { |s| s[:value] }.max
    all_stats.select { |s| s[:value] == max_value }
  end

  # Calculate brick wall (best goals against per game - defensive prowess, handles ties)
  def calculate_brick_wall
    all_stats = fan_teams
      .map do |team|
        goals_against_per_game = team['goalAgainst'] || 999
        
        abbrev = team['teamAbbrev']['default']
        {
          fan: @manager_team_map[abbrev],
          team: team['teamName']['default'],
          value: goals_against_per_game,
          display: "#{goals_against_per_game} goals against/game"
        }
      end
    
    return nil if all_stats.empty?
    
    min_value = all_stats.map { |s| s[:value] }.min
    all_stats.select { |s| s[:value] == min_value }
  end

  # Calculate glass cannon (highest goals for but negative goal differential - scoring but losing, handles ties)
  def calculate_glass_cannon
    all_stats = fan_teams
      .map do |team|
        goals_for = team['goalsForPctg'] || 0
        goals_against = team['goalAgainst'] || 0
        differential = goals_for - goals_against
        
        # Only consider teams with negative differential but high scoring
        next nil if differential >= 0 || goals_for < 2.5
        
        abbrev = team['teamAbbrev']['default']
        {
          fan: @manager_team_map[abbrev],
          team: team['teamName']['default'],
          value: goals_for,
          display: "#{goals_for} goals/game but #{differential.round(2)} differential"
        }
      end
      .compact
    
    return nil if all_stats.empty?
    
    max_value = all_stats.map { |s| s[:value] }.max
    all_stats.select { |s| s[:value] == max_value }
  end

  # Calculate comeback kid (most OT/shootout wins - clutch performance, handles ties)
  def calculate_comeback_kid
    all_stats = fan_teams
      .map do |team|
        wins = team['wins'] || 0
        regulation_wins = team['regulationWins'] || wins  # Fall back to total wins if regulationWins not available
        ot_wins = wins - regulation_wins
        
        next nil if ot_wins <= 0
        
        abbrev = team['teamAbbrev']['default']
        {
          fan: @manager_team_map[abbrev],
          team: team['teamName']['default'],
          value: ot_wins,
          display: "#{ot_wins} OT/SO #{ot_wins == 1 ? 'win' : 'wins'}"
        }
      end
      .compact
    
    return nil if all_stats.empty?
    
    max_value = all_stats.map { |s| s[:value] }.max
    all_stats.select { |s| s[:value] == max_value }
  end

  # Calculate "Overtimer" - most overtime losses (lives dangerously, handles ties)
  def calculate_overtimer
    all_stats = fan_teams
      .map do |team|
        ot_losses = team['otLosses'] || 0
        
        next nil if ot_losses == 0
        
        abbrev = team['teamAbbrev']['default']
        {
          fan: @manager_team_map[abbrev],
          team: team['teamName']['default'],
          value: ot_losses,
          display: "#{ot_losses} overtime #{ot_losses == 1 ? 'loss' : 'losses'} (living on the edge!)"
        }
      end
      .compact
    
    return nil if all_stats.empty?
    
    max_value = all_stats.map { |s| s[:value] }.max
    all_stats.select { |s| s[:value] == max_value }
  end

  # Calculate "Point Scrounger" - most points from OT losses (getting points despite losing, handles ties)
  def calculate_point_scrounger
    all_stats = fan_teams
      .map do |team|
        ot_losses = team['otLosses'] || 0
        
        next nil if ot_losses == 0
        
        abbrev = team['teamAbbrev']['default']
        {
          fan: @manager_team_map[abbrev],
          team: team['teamName']['default'],
          value: ot_losses,
          display: "#{ot_losses} pity #{ot_losses == 1 ? 'point' : 'points'} from OT losses"
        }
      end
      .compact
    
    return nil if all_stats.empty?
    
    max_value = all_stats.map { |s| s[:value] }.max
    all_stats.select { |s| s[:value] == max_value }
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
    # Extract the number from the streak code (e.g., "W3" -> 3, "L2" -> 2)
    # If no number is present (just "W" or "L") or if it's 0, default to 1
    streak_num_raw = streak_code.scan(/\d+/).first&.to_i
    streak_num = (streak_num_raw.nil? || streak_num_raw == 0) ? 1 : streak_num_raw
    streak_type = streak_code.start_with?('W') ? 'wins' : 'losses'
    
    {
      fan: @manager_team_map[abbrev],
      team: team['teamName']['default'],
      value: streak_num,
      display: "#{streak_num} game #{streak_type} (#{streak_code})"
    }
  end

  # Helper to find team by abbreviation
  def find_team_by_abbrev(abbrev)
    @teams.find { |t| t['teamAbbrev']['default'] == abbrev }
  end

  # Fetch head-to-head records for all fan teams from NHL API
  def fetch_head_to_head_records
    require 'net/http'
    require 'json'
    require 'uri'
    
    @head_to_head_matrix = {}
    fan_abbrevs = fan_teams.map { |t| t['teamAbbrev']['default'] }
    
    # For each fan team, get their season schedule and extract games vs other fan teams
    fan_abbrevs.each do |team_abbrev|
      @head_to_head_matrix[team_abbrev] = {}
      
      begin
        # Fetch season schedule from NHL API
        # Determine current season based on date
        current_year = Time.now.year
        current_month = Time.now.month
        # NHL season runs from October to June
        season = current_month >= 10 ? "#{current_year}#{current_year + 1}" : "#{current_year - 1}#{current_year}"
        url = URI("https://api-web.nhle.com/v1/club-schedule-season/#{team_abbrev}/#{season}")
        
        response = Net::HTTP.get_response(url)
        next unless response.is_a?(Net::HTTPSuccess)
        
        schedule_data = JSON.parse(response.body)
        games = schedule_data['games'] || []
        
        # Process each game to find matchups vs other fan teams
        games.each do |game|
          next unless game['gameState'] == 3 || game['gameState'] == 4 || game['gameState'] == 5 # Final, Official, or Archived
          
          home_abbrev = game['homeTeam']['abbrev']
          away_abbrev = game['awayTeam']['abbrev']
          
          # Determine if this is a fan vs fan game
          opponent_abbrev = nil
          we_are_home = (home_abbrev == team_abbrev)
          
          if we_are_home && fan_abbrevs.include?(away_abbrev)
            opponent_abbrev = away_abbrev
          elsif !we_are_home && fan_abbrevs.include?(home_abbrev)
            opponent_abbrev = home_abbrev
          end
          
          next unless opponent_abbrev
          
          # Initialize record if needed
          @head_to_head_matrix[team_abbrev][opponent_abbrev] ||= { wins: 0, losses: 0, ot_losses: 0 }
          
          # Determine outcome
          home_score = game['homeTeam']['score']
          away_score = game['awayTeam']['score']
          
          if we_are_home
            if home_score > away_score
              @head_to_head_matrix[team_abbrev][opponent_abbrev][:wins] += 1
            elsif game['periodDescriptor'] && game['periodDescriptor']['periodType'] != 'REG'
              # Lost in OT/SO
              @head_to_head_matrix[team_abbrev][opponent_abbrev][:ot_losses] += 1
            else
              @head_to_head_matrix[team_abbrev][opponent_abbrev][:losses] += 1
            end
          else
            if away_score > home_score
              @head_to_head_matrix[team_abbrev][opponent_abbrev][:wins] += 1
            elsif game['periodDescriptor'] && game['periodDescriptor']['periodType'] != 'REG'
              # Lost in OT/SO
              @head_to_head_matrix[team_abbrev][opponent_abbrev][:ot_losses] += 1
            else
              @head_to_head_matrix[team_abbrev][opponent_abbrev][:losses] += 1
            end
          end
        end
      rescue StandardError => e
        # Log error but continue with other teams
        puts "Error fetching schedule for #{team_abbrev}: #{e.message}"
        next
      end
    end
  end

  # Calculate "Fan Crusher" - best record vs other fan teams
  def calculate_fan_crusher
    return nil if @head_to_head_matrix.nil? || @head_to_head_matrix.empty?
    
    all_stats = fan_teams.map do |team|
      abbrev = team['teamAbbrev']['default']
      h2h_records = @head_to_head_matrix[abbrev] || {}
      
      total_wins = h2h_records.values.sum { |r| r[:wins] }
      total_losses = h2h_records.values.sum { |r| r[:losses] + r[:ot_losses] }
      total_games = total_wins + total_losses
      
      next nil if total_games == 0
      
      win_pct = (total_wins.to_f / total_games * 100).round(1)
      
      {
        fan: @manager_team_map[abbrev],
        team: team['teamName']['default'],
        value: win_pct,
        display: "#{total_wins}-#{total_losses} (#{win_pct}% vs other fans)"
      }
    end.compact
    
    return nil if all_stats.empty?
    
    max_value = all_stats.map { |s| s[:value] }.max
    all_stats.select { |s| s[:value] == max_value }
  end

  # Calculate "Fan Fodder" - worst record vs other fan teams
  def calculate_fan_fodder
    return nil if @head_to_head_matrix.nil? || @head_to_head_matrix.empty?
    
    all_stats = fan_teams.map do |team|
      abbrev = team['teamAbbrev']['default']
      h2h_records = @head_to_head_matrix[abbrev] || {}
      
      total_wins = h2h_records.values.sum { |r| r[:wins] }
      total_losses = h2h_records.values.sum { |r| r[:losses] + r[:ot_losses] }
      total_games = total_wins + total_losses
      
      next nil if total_games == 0
      
      win_pct = (total_wins.to_f / total_games * 100).round(1)
      
      {
        fan: @manager_team_map[abbrev],
        team: team['teamName']['default'],
        value: win_pct,
        display: "#{total_wins}-#{total_losses} (#{win_pct}% vs other fans)"
      }
    end.compact
    
    return nil if all_stats.empty?
    
    min_value = all_stats.map { |s| s[:value] }.min
    all_stats.select { |s| s[:value] == min_value }
  end
end
