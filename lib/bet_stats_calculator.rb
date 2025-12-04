# filepath: /home/runner/work/hockey_bet/hockey_bet/lib/bet_stats_calculator.rb
require 'csv'
require 'set'
require_relative 'historical_stats_tracker'

# BetStatsCalculator computes various statistical rankings and achievements
# for fantasy hockey league participants based on NHL team performance data.
# It generates rankings like top winners, best cup odds, head-to-head records,
# and special achievements like "brick wall" (best defense) or "glass cannon" (high scoring).
class BetStatsCalculator
  attr_reader :stats
  
  # Constants for Stanley Cup odds calculation
  PLAYOFF_TEAM_COUNT = 16  # Total number of playoff teams
  CONFERENCE_PLAYOFF_SPOTS = 8  # Number of playoff spots per conference
  CONFERENCE_BONUS_MULTIPLIER = 5.0  # Bonus multiplier for conference position
  
  # Constants for stat calculations
  TOP_MATCHUPS_TO_SHOW = 3  # Number of top matchups to display
  MINIMUM_SCORING_RATE = 2.5  # Minimum goals/game for glass cannon consideration
  EXCEPTIONAL_DEFENSE_THRESHOLD = 2.5  # Max goals against/game for shutout king
  STANLEY_CUP_WINS_REQUIRED = 16  # Playoff wins needed to win Stanley Cup
  HALL_OF_FAME_LOOKBACK_YEARS = 6  # Years to look back for championship history

  # Initializes the calculator with team data and mappings
  # @param teams [Array<Hash>] NHL team data from API
  # @param manager_team_map [Hash] Maps team abbreviations to fan/manager names
  # @param next_games [Hash] Upcoming game information for each team
  # @param historical_tracker [HistoricalStatsTracker, nil] Optional tracker for historical data
  def initialize(teams, manager_team_map, next_games, historical_tracker = nil)
    @teams = teams
    @manager_team_map = manager_team_map
    @next_games = next_games
    @stats = {}
    @historical_tracker = historical_tracker || HistoricalStatsTracker.new
    @team_lookup_cache = {} # Cache for team lookups by abbreviation
  end

  # Calculate all bet stats and achievements
  # This is the main entry point that computes all statistics and rankings
  # @return [Hash] All calculated statistics keyed by stat name
  def calculate_all_stats
    # Fetch head-to-head data first (needed for some stats)
    fetch_head_to_head_records
    
    # Calculate Stanley Cup odds for all teams
    calculate_stanley_cup_odds
    
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
      fan_fodder: calculate_fan_fodder,
      best_cup_odds: calculate_best_cup_odds,
      worst_cup_odds: calculate_worst_cup_odds,
      shutout_king: calculate_shutout_king,
      momentum_master: calculate_momentum_master,
      dynasty_points: calculate_dynasty_points,
      most_improved: calculate_most_improved,
      hall_of_fame: calculate_hall_of_fame,
      sharks_victims: calculate_sharks_victims,
      predators_victims: calculate_predators_victims
    }
  end

  # Get teams owned by fans (excluding "N/A")
  def fan_teams
    @fan_teams ||= @teams.select do |team|
      abbrev = team['teamAbbrev']['default']
      @manager_team_map[abbrev] && @manager_team_map[abbrev] != "N/A"
    end
  end

  # Calculate top 3 fans with most wins (handles ties at medal positions)
  # @return [Array<Hash>] Top winners with fan name, team, value, and display
  def calculate_top_winners
    calculate_simple_ranking('wins', descending: true, suffix: " wins")
  end

  # Calculate top 3 fans with most losses (handles ties at medal positions)
  # @return [Array<Hash>] Top losers with fan name, team, value, and display
  def calculate_top_losers
    calculate_simple_ranking('losses', descending: true, suffix: " losses")
  end

  # Find most interesting upcoming fan vs fan matchups
  # Calculates an "interest score" based on how close teams are in standings.
  # Closer matchups are more interesting. Returns top 3 matchups.
  # @return [Array<Hash>] Top matchups with fan names, teams, points, and game time
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
        home_abbrev: home_abbrev,
        away_abbrev: away_abbrev,
        home_wins: home_team['wins'] || 0,
        away_wins: away_team['wins'] || 0,
        home_points: home_points,
        away_points: away_points,
        interest_score: interest_score,
        game_time: game['startTimeUTC']
      }
    end
    
    matchups.sort_by { |m| -m[:interest_score] }.take(TOP_MATCHUPS_TO_SHOW)
  end

  # Calculate fan with longest winning streak (handles ties)
  def calculate_longest_win_streak
    all_streaks = fan_teams
      .select { |team| team['streakCode'] && team['streakCode'].start_with?('W') }
      .map { |team| create_streak_stat(team) }
    
    return nil if all_streaks.empty?
    
    # Sort by value descending and return top 3, including ties
    sorted = all_streaks.sort_by { |s| -s[:value] }
    top_3_with_ties(sorted, descending: true)
  end

  # Calculate fan with longest losing streak (returns top 3, including ties)
  def calculate_longest_lose_streak
    all_streaks = fan_teams
      .select { |team| team['streakCode'] && team['streakCode'].start_with?('L') }
      .map { |team| create_streak_stat(team) }
    
    return nil if all_streaks.empty?
    
    # Sort by value descending and return top 3, including ties
    sorted = all_streaks.sort_by { |s| -s[:value] }
    top_3_with_ties(sorted, descending: true)
  end

  # Calculate fan with best goal differential (returns top 3)
  def calculate_best_point_differential
    all_stats = fan_teams
      .map do |team|
        gp = games_played(team)
        next nil if gp == 0
        
        # Calculate per-game averages - handle both API formats
        goals_for_per_game = if team.key?('goalFor') && !team['goalFor'].nil?
          team['goalFor'].to_f / gp
        elsif team.key?('goalsForPctg') && !team['goalsForPctg'].nil?
          team['goalsForPctg'].to_f
        else
          0.0
        end
        
        goals_against_per_game = if team.key?('goalAgainst') && !team['goalAgainst'].nil?
          team['goalAgainst'].to_f / gp
        else
          0.0
        end
        
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
    
    # Sort by value descending and return top 3, including ties
    sorted = all_stats.sort_by { |s| -s[:value] }
    top_3_with_ties(sorted, descending: true)
  end

  # Calculate most dominant (best win percentage, returns top 3, including ties)
  # @return [Array<Hash>, nil] Top teams by win percentage or nil if none
  def calculate_most_dominant
    all_stats = fan_teams
      .map do |team|
        gp = games_played(team)
        next nil if gp == 0
        
        wins = team['wins'] || 0
        win_pct = (wins.to_f / gp * 100).round(1)
        
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
    
    # Sort by value descending and return top 3, including ties
    sorted = all_stats.sort_by { |s| -s[:value] }
    top_3_with_ties(sorted, descending: true)
  end

  # Calculate brick wall (best goals against per game - defensive prowess, returns top 3)
  def calculate_brick_wall
    all_stats = fan_teams
      .map do |team|
        gp = games_played(team)
        next nil if gp == 0
        
        # Handle both API formats: goalAgainst (total) vs already per-game average
        goals_against_per_game = if team.key?('goalAgainst') && !team['goalAgainst'].nil?
          team['goalAgainst'].to_f / gp
        else
          0.0
        end
        
        abbrev = team['teamAbbrev']['default']
        {
          fan: @manager_team_map[abbrev],
          team: team['teamName']['default'],
          team_abbrev: abbrev,
          value: goals_against_per_game,
          display: "#{goals_against_per_game.round(2)} goals against/game"
        }
      end
      .compact
    
    return nil if all_stats.empty?
    
    # Sort by value ascending (lowest goals against is best) and return top 3, including ties
    sorted = all_stats.sort_by { |s| s[:value] }
    top_3_with_ties(sorted, descending: false)
  end

  # Calculate glass cannon (highest goals for but negative goal differential - scoring but losing, returns top 3, including ties)
  # Teams that score a lot but still lose games are considered "glass cannons"
  # @return [Array<Hash>, nil] Top glass cannon teams or nil if none qualify
  def calculate_glass_cannon
    all_stats = fan_teams
      .map do |team|
        gp = games_played(team)
        next nil if gp == 0
        
        # Handle both API formats explicitly
        goals_for = if team.key?('goalFor') && !team['goalFor'].nil?
          team['goalFor'].to_f / gp
        elsif team.key?('goalsForPctg') && !team['goalsForPctg'].nil?
          team['goalsForPctg'].to_f
        else
          0.0
        end
        
        goals_against = if team.key?('goalAgainst') && !team['goalAgainst'].nil?
          team['goalAgainst'].to_f / gp
        else
          0.0
        end
        
        differential = goals_for - goals_against
        
        # Only consider teams with negative differential but high scoring
        next nil if differential >= 0 || goals_for < MINIMUM_SCORING_RATE
        
        abbrev = team['teamAbbrev']['default']
        {
          fan: @manager_team_map[abbrev],
          team: team['teamName']['default'],
          team_abbrev: abbrev,
          value: goals_for,
          display: "#{goals_for.round(2)} goals/game but #{differential.round(2)} differential"
        }
      end
      .compact
    
    return nil if all_stats.empty?
    
    # Sort by value descending and return top 3, including ties
    sorted = all_stats.sort_by { |s| -s[:value] }
    top_3_with_ties(sorted, descending: true)
  end

  # Calculate comeback kid (most OT/shootout wins - clutch performance, returns top 3)
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
    
    # Sort by value descending and return top 3, including ties
    sorted = all_stats.sort_by { |s| -s[:value] }
    top_3_with_ties(sorted, descending: true)
  end

  # Calculate "Overtimer" - most overtime losses (lives dangerously, returns top 3, including ties)
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
    
    # Sort by value descending and return top 3, including ties
    sorted = all_stats.sort_by { |s| -s[:value] }
    top_3_with_ties(sorted, descending: true)
  end

  # Calculate "Point Scrounger" - most points from OT losses (getting points despite losing, returns top 3, including ties)
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
    
    # Sort by value descending and return top 3, including ties
    sorted = all_stats.sort_by { |s| -s[:value] }
    top_3_with_ties(sorted, descending: true)
  end

  # Calculate "Fan Crusher" - most wins vs other fan teams (returns top 3)
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
        value: total_wins,  # Changed: sort by total wins instead of win %
        wins: total_wins,
        losses: total_losses,
        win_pct: win_pct,
        display: "#{total_wins}-#{total_losses} (#{win_pct}% vs other fans)"
      }
    end.compact
    
    return nil if all_stats.empty?
    
    # Sort by total wins descending, then by win % as tiebreaker
    sorted = all_stats.sort_by { |s| [-s[:value], -s[:win_pct]] }
    top_3_with_ties(sorted, descending: true)
  end

  # Calculate "Fan Fodder" - worst record vs other fan teams (returns top 3, including ties)
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
        value: total_losses,  # Changed: use total losses instead of win %
        display: "#{total_wins}-#{total_losses} (#{total_losses} losses vs other fans)"
      }
    end.compact
    
    return nil if all_stats.empty?
    
    # Sort by value descending (most losses) and return top 3, including ties
    sorted = all_stats.sort_by { |s| -s[:value] }
    top_3_with_ties(sorted, descending: true)
  end

  # Calculate Stanley Cup odds for each team based on regular season standings
  # Uses conference position, division position, and point percentage
  def calculate_stanley_cup_odds
    @cup_odds = {}
    
    # Calculate odds for each team
    @teams.each do |team|
      abbrev = team['teamAbbrev']['default']
      
      # Base odds on multiple factors:
      # 1. Division position (top 3 in division get playoff spots)
      # 2. Conference position (wildcards)
      # 3. Point percentage (overall strength)
      # 4. League sequence (overall ranking)
      
      division_seq = team['divisionSequence'].to_i
      conference_seq = team['conferenceSequence'].to_i
      point_pctg = team['pointPctg'].to_f
      league_seq = team['leagueSequence'].to_i
      
      # Calculate base odds
      # Teams ranked 1-16 in league get decreasing odds (top playoff teams)
      base_odds = if league_seq > 0 && league_seq <= PLAYOFF_TEAM_COUNT
                    100.0 / league_seq  # Higher ranking = better odds
                  else
                    0.1  # Very low odds for non-playoff teams
                  end
      
      # Bonus for division leaders (top 3 in division)
      division_bonus = case division_seq
                       when 1 then 20.0
                       when 2 then 15.0
                       when 3 then 10.0
                       else 0.0
                       end
      
      # Bonus for conference position (top 8 make playoffs in each conference)
      conference_bonus = if conference_seq <= CONFERENCE_PLAYOFF_SPOTS
                          (CONFERENCE_PLAYOFF_SPOTS + 1 - conference_seq) * CONFERENCE_BONUS_MULTIPLIER
                        else
                          0.0
                        end
      
      # Point percentage bonus (max 25 points for perfect 1.000)
      point_bonus = point_pctg * 25.0
      
      # Calculate total odds score
      odds_score = base_odds + division_bonus + conference_bonus + point_bonus
      
      @cup_odds[abbrev] = odds_score
    end
    
    # Normalize odds to sum to 100%
    total_odds = @cup_odds.values.sum
    if total_odds > 0
      @cup_odds.each do |abbrev, odds|
        @cup_odds[abbrev] = ((odds / total_odds) * 100).round(2)
      end
    end
  end

  # Calculate fan with best Stanley Cup odds
  def calculate_best_cup_odds
    return nil if @cup_odds.nil? || @cup_odds.empty?
    
    all_stats = fan_teams.map do |team|
      abbrev = team['teamAbbrev']['default']
      odds = @cup_odds[abbrev] || 0.0
      
      division_seq = team['divisionSequence'].to_i
      conference_seq = team['conferenceSequence'].to_i
      
      # Include conference and division info in the display
      position_info = []
      position_info << "#{get_ordinal(division_seq)} in division" if division_seq > 0
      position_info << "#{get_ordinal(conference_seq)} in conference" if conference_seq > 0
      
      {
        fan: @manager_team_map[abbrev],
        team: team['teamName']['default'],
        team_abbrev: abbrev,
        value: odds,
        division_sequence: division_seq,
        conference_sequence: conference_seq,
        display: "#{odds}% cup odds (#{position_info.join(', ')})"
      }
    end.compact
    
    return nil if all_stats.empty?
    
    # Sort by odds descending and return top 3, including ties
    sorted = all_stats.sort_by { |s| -s[:value] }
    top_3_with_ties(sorted, descending: true)
  end

  # Calculate fan with worst Stanley Cup odds
  def calculate_worst_cup_odds
    return nil if @cup_odds.nil? || @cup_odds.empty?
    
    all_stats = fan_teams.map do |team|
      abbrev = team['teamAbbrev']['default']
      odds = @cup_odds[abbrev] || 0.0
      
      division_seq = team['divisionSequence'].to_i
      conference_seq = team['conferenceSequence'].to_i
      
      # Include conference and division info in the display
      position_info = []
      position_info << "#{get_ordinal(division_seq)} in division" if division_seq > 0
      position_info << "#{get_ordinal(conference_seq)} in conference" if conference_seq > 0
      
      {
        fan: @manager_team_map[abbrev],
        team: team['teamName']['default'],
        team_abbrev: abbrev,
        value: odds,
        division_sequence: division_seq,
        conference_sequence: conference_seq,
        display: "#{odds}% cup odds (#{position_info.join(', ')})"
      }
    end.compact
    
    return nil if all_stats.empty?
    
    # Sort by odds ascending (worst odds first) and return bottom 3, including ties
    sorted = all_stats.sort_by { |s| s[:value] }
    top_3_with_ties(sorted, descending: false)
  end

  # Calculate "Shutout King" - most games with 0 goals against (defensive excellence)
  def calculate_shutout_king
    # This would require game-by-game data. As a proxy, we'll use teams with
    # the best goals against per game and highlight the best defensive performance
    all_stats = fan_teams
      .map do |team|
        gp = games_played(team)
        next nil if gp == 0
        
        goals_against = team['goalAgainst']
        next nil unless goals_against && goals_against.is_a?(Numeric)
        
        # Calculate average goals against
        ga_per_game = goals_against.to_f / gp
        
        # Only include teams with exceptional defense (under threshold)
        next nil if ga_per_game > EXCEPTIONAL_DEFENSE_THRESHOLD
        
        abbrev = team['teamAbbrev']['default']
        {
          fan: @manager_team_map[abbrev],
          team: team['teamName']['default'],
          team_abbrev: abbrev,
          value: -ga_per_game,  # Negative so lower is better
          display: "#{ga_per_game.round(2)} goals against/game (defensive fortress)"
        }
      end
      .compact
    
    return nil if all_stats.empty?
    
    # Sort by value descending (least goals against) and return top 3
    sorted = all_stats.sort_by { |s| -s[:value] }
    top_3_with_ties(sorted, descending: true)
  end

  # Calculate "Momentum Master" - longest active point streak
  def calculate_momentum_master
    # Point streak = consecutive games earning at least 1 point (win or OT loss)
    # This requires tracking current streak which we can infer from recent performance
    # We'll use current streak code as a proxy for momentum
    all_stats = fan_teams
      .select { |team| team['streakCode'] }
      .map do |team|
        streak_code = team['streakCode']
        
        # Use streakCount if available, otherwise parse from streakCode
        if team['streakCount']
          streak_num = team['streakCount']
        else
          streak_num_raw = streak_code.scan(/\d+/).first&.to_i
          streak_num = (streak_num_raw.nil? || streak_num_raw == 0) ? 1 : streak_num_raw
        end
        
        # Point streaks include both wins (W) and OT losses (OT)
        # We'll count win streaks as point streaks
        is_point_streak = streak_code.start_with?('W')
        next nil unless is_point_streak
        
        abbrev = team['teamAbbrev']['default']
        {
          fan: @manager_team_map[abbrev],
          team: team['teamName']['default'],
          value: streak_num,
          display: "#{streak_num}-game point streak (riding the wave 🌊)"
        }
      end
      .compact
    
    return nil if all_stats.empty?
    
    # Sort by value descending and return top 3, including ties
    sorted = all_stats.sort_by { |s| -s[:value] }
    top_3_with_ties(sorted, descending: true)
  end

  # Calculate "Dynasty Points" - cumulative playoff wins across all seasons
  def calculate_dynasty_points
    all_stats = []
    
    # Get all fans who have teams
    fan_teams.each do |team|
      abbrev = team['teamAbbrev']['default']
      fan = @manager_team_map[abbrev]
      
      # Get total playoff wins from historical data
      total_playoff_wins = @historical_tracker.total_playoff_wins(fan)
      
      # Only include fans with playoff wins
      next if total_playoff_wins == 0
      
      all_stats << {
        fan: fan,
        team: team['teamName']['default'],
        value: total_playoff_wins,
        display: "#{total_playoff_wins} playoff #{total_playoff_wins == 1 ? 'win' : 'wins'} (all-time)"
      }
    end
    
    return nil if all_stats.empty?
    
    # Sort by playoff wins descending and return top 3
    sorted = all_stats.sort_by { |s| -s[:value] }
    top_3_with_ties(sorted, descending: true)
  end

  # Calculate "Most Improved" - biggest improvement from previous season
  def calculate_most_improved
    all_stats = []
    current_season = @historical_tracker.current_season
    
    # Parse current season to get previous season
    if current_season =~ /(\d{4})-(\d{4})/
      prev_year = $1.to_i - 1
      current_year = $2.to_i - 1
      previous_season = "#{prev_year}-#{current_year}"
    else
      return nil # Can't calculate without proper season format
    end
    
    fan_teams.each do |team|
      abbrev = team['teamAbbrev']['default']
      fan = @manager_team_map[abbrev]
      
      # Get improvement stats
      improvement = @historical_tracker.calculate_improvement(fan, previous_season, current_season)
      next unless improvement
      
      # Calculate composite improvement score
      # Prioritize wins improvement, but also consider points and ranking
      score = (improvement[:wins_diff] * 3) + 
              (improvement[:points_diff] * 1) + 
              (improvement[:rank_improvement] * 2)
      
      # Only show positive improvements
      next if score <= 0
      
      all_stats << {
        fan: fan,
        team: team['teamName']['default'],
        value: score,
        wins_diff: improvement[:wins_diff],
        points_diff: improvement[:points_diff],
        display: "+#{improvement[:wins_diff]} wins, +#{improvement[:points_diff]} points vs last season"
      }
    end
    
    return nil if all_stats.empty?
    
    # Sort by improvement score descending and return top 3
    sorted = all_stats.sort_by { |s| -s[:value] }
    top_3_with_ties(sorted, descending: true)
  end

  # Save current season stats to historical tracking
  def record_current_season_stats
    current_season = @historical_tracker.current_season
    
    fan_teams.each do |team|
      abbrev = team['teamAbbrev']['default']
      fan = @manager_team_map[abbrev]
      
      stats = {
        wins: team['wins'] || 0,
        losses: team['losses'] || 0,
        ot_losses: team['otLosses'] || 0,
        points: team['points'] || 0,
        goals_for: team['goalFor'] || 0,
        goals_against: team['goalAgainst'] || 0,
        division_rank: team['divisionSequence'] || 0,
        conference_rank: team['conferenceSequence'] || 0,
        league_rank: team['leagueSequence'] || 0,
        playoff_wins: 0 # This would need to be updated separately during playoffs
      }
      
      @historical_tracker.record_season_stats(current_season, fan, abbrev, stats)
    end
  end

  private

  # Helper to return top 3 from sorted array, including ties at 3rd place
  def top_3_with_ties(sorted_stats, descending: true)
    return sorted_stats if sorted_stats.size <= 3
    
    # Get the value of the 3rd place
    third_value = sorted_stats[2][:value]
    
    # Return all with value equal to or better than 3rd place
    if descending
      sorted_stats.select { |s| s[:value] >= third_value }
    else
      sorted_stats.select { |s| s[:value] <= third_value }
    end
  end

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
    # Use streakCount if available (current API format), otherwise parse from streakCode (legacy format)
    if team['streakCount']
      streak_num = team['streakCount']
    else
      # Extract the number from the streak code (e.g., "W3" -> 3, "L2" -> 2)
      # If no number is present (just "W" or "L") or if it's 0, default to 1
      streak_num_raw = streak_code.scan(/\d+/).first&.to_i
      streak_num = (streak_num_raw.nil? || streak_num_raw == 0) ? 1 : streak_num_raw
    end
    streak_type = streak_code.start_with?('W') ? 'wins' : 'losses'
    
    {
      fan: @manager_team_map[abbrev],
      team: team['teamName']['default'],
      team_abbrev: abbrev,
      value: streak_num,
      display: "#{streak_num} game #{streak_type} (#{streak_code})"
    }
  end

  # Helper to calculate games played from team data
  # Handles both explicit gamesPlayed field and calculated from W/L/OTL
  # @param team [Hash] Team data
  # @return [Integer] Number of games played
  def games_played(team)
    team['gamesPlayed'] || ((team['wins'] || 0) + (team['losses'] || 0) + (team['otLosses'] || 0))
  end

  # Helper to find team by abbreviation with caching for performance
  # @param abbrev [String] Team abbreviation (e.g., "BOS", "TOR")
  # @return [Hash, nil] Team data or nil if not found
  def find_team_by_abbrev(abbrev)
    return @team_lookup_cache[abbrev] if @team_lookup_cache.key?(abbrev)
    
    team = @teams.find { |t| t['teamAbbrev']['default'] == abbrev }
    @team_lookup_cache[abbrev] = team
    team
  end

  # Generic helper for calculating simple top-N rankings
  # Reduces code duplication across similar stat calculations
  # @param field [String, Symbol] The team data field to rank by
  # @param descending [Boolean] Sort order (true for high-to-low, false for low-to-high)
  # @param suffix [String] Optional suffix for display value (e.g., " wins")
  # @return [Array<Hash>] Top-ranked stats with ties handled properly
  def calculate_simple_ranking(field, descending: true, suffix: "")
    all_stats = fan_teams
      .map { |team| create_fan_stat(team, team[field.to_s] || 0, suffix: suffix) }
      .sort_by { |stat| descending ? -stat[:value] : stat[:value] }
    
    filter_top_positions(all_stats)
  end

  # Filter stats to only show top 3 positions (Olympic-style ranking)
  # When there's a tie, teams share the position and the next team
  # gets the position after accounting for the tie
  # E.g., if 2 teams tie for 1st, the next team is in 3rd (not 2nd)
  def filter_top_positions(all_stats)
    return [] if all_stats.empty?
    
    result = []
    position = 0
    last_value = nil
    
    all_stats.each_with_index do |stat, index|
      # Check if this is a new value
      if stat[:value] != last_value
        # Update position to current index + 1 (1-indexed)
        position = index + 1
        # Stop if we're past the top 3 positions
        break if position > 3
        last_value = stat[:value]
      end
      
      result << stat
    end
    
    result
  end

  # Fetch head-to-head records for all fan teams from NHL API
  def fetch_head_to_head_records
    require 'net/http'
    require 'json'
    require 'uri'
    
    @head_to_head_matrix = {}
    fan_abbrevs = fan_teams.map { |t| t['teamAbbrev']['default'] }
    
    # Determine current season based on date
    current_year = Time.now.year
    current_month = Time.now.month
    # NHL season runs from October to June
    # If we're in October-December, use current year as start (e.g., Oct 2024 = 20242025 season)
    # If we're in January-September, use previous year as start (e.g., Mar 2025 = 20242025 season)
    season = current_month >= 10 ? "#{current_year}#{current_year + 1}" : "#{current_year - 1}#{current_year}"
    
    puts "Fetching head-to-head records for #{season} season (#{fan_abbrevs.length} teams)..."
    puts "Current date: #{Time.now.strftime('%Y-%m-%d')}"
    
    # Track processed games to avoid counting the same game twice
    # (since each game appears in both teams' schedules)
    processed_game_ids = Set.new
    
    # For each fan team, get their season schedule and extract games vs other fan teams
    fan_abbrevs.each do |team_abbrev|
      @head_to_head_matrix[team_abbrev] ||= {}
      
      begin
        # Fetch season schedule from NHL API
        url = URI("https://api-web.nhle.com/v1/club-schedule-season/#{team_abbrev}/#{season}")
        
        response = Net::HTTP.get_response(url)
        next unless response.is_a?(Net::HTTPSuccess)
        
        schedule_data = JSON.parse(response.body)
        games = schedule_data['games'] || []
        
        # Track stats for verification
        completed_games = 0
        fan_matchup_games = 0
        first_game_date = nil
        last_game_date = nil
        
        # Process each game to find matchups vs other fan teams
        games.each do |game|
          # Check if game is completed - handle both numeric and string game states
          game_state = game['gameState']
          is_completed = case game_state
                        when Integer
                          [3, 4, 5, 6, 7].include?(game_state) # Final (3), Official Final (4), Final (5), and other final states
                        when String
                          ['OFF', 'FINAL', 'OVER'].include?(game_state.upcase) # String final states
                        else
                          false
                        end
          next unless is_completed
          
          completed_games += 1
          
          # Track game date range
          game_date = game['gameDate'] || game['startTimeUTC']
          if game_date
            first_game_date = game_date if first_game_date.nil? || game_date < first_game_date
            last_game_date = game_date if last_game_date.nil? || game_date > last_game_date
          end
          
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
          
          # Get unique game identifier
          game_id = game['id']
          
          # Skip games without IDs - we can't reliably deduplicate them
          unless game_id
            puts "  Warning: Skipping game without ID: #{home_abbrev} vs #{away_abbrev}"
            next
          end
          
          # Skip preseason games (game IDs like 2025010xxx)
          # Regular season games have IDs like 2025020xxx
          # We only want regular season games for head-to-head records
          game_id_str = game_id.to_s
          if game_id_str.length >= 6 && game_id_str[4..5] != '02'
            # This is not a regular season game (could be preseason 01 or playoffs 03)
            next
          end
          
          # Skip if we've already processed this game
          # (games appear in both teams' schedules)
          if processed_game_ids.include?(game_id)
            next
          end
          
          # Mark this game as processed
          processed_game_ids.add(game_id)
          
          fan_matchup_games += 1
          
          # Debug logging for specific matchups if requested
          if ENV['DEBUG_H2H']
            puts "    Processing game #{game_id}: #{home_abbrev} (#{game['homeTeam']['score']}) vs #{away_abbrev} (#{game['awayTeam']['score']}) on #{game_date}"
          end
          
          # Initialize records for both teams if needed
          @head_to_head_matrix[team_abbrev][opponent_abbrev] ||= { wins: 0, losses: 0, ot_losses: 0 }
          @head_to_head_matrix[opponent_abbrev] ||= {}
          @head_to_head_matrix[opponent_abbrev][team_abbrev] ||= { wins: 0, losses: 0, ot_losses: 0 }
          
          # Determine outcome
          home_score = game['homeTeam']['score']
          away_score = game['awayTeam']['score']
          
          if we_are_home
            if home_score > away_score
              # We (home) won
              @head_to_head_matrix[team_abbrev][opponent_abbrev][:wins] += 1
              # Opponent (away) lost
              if game['periodDescriptor'] && game['periodDescriptor']['periodType'] != 'REG'
                @head_to_head_matrix[opponent_abbrev][team_abbrev][:ot_losses] += 1
              else
                @head_to_head_matrix[opponent_abbrev][team_abbrev][:losses] += 1
              end
            elsif game['periodDescriptor'] && game['periodDescriptor']['periodType'] != 'REG'
              # We (home) lost in OT/SO
              @head_to_head_matrix[team_abbrev][opponent_abbrev][:ot_losses] += 1
              # Opponent (away) won
              @head_to_head_matrix[opponent_abbrev][team_abbrev][:wins] += 1
            else
              # We (home) lost in regulation
              @head_to_head_matrix[team_abbrev][opponent_abbrev][:losses] += 1
              # Opponent (away) won
              @head_to_head_matrix[opponent_abbrev][team_abbrev][:wins] += 1
            end
          else
            if away_score > home_score
              # We (away) won
              @head_to_head_matrix[team_abbrev][opponent_abbrev][:wins] += 1
              # Opponent (home) lost
              if game['periodDescriptor'] && game['periodDescriptor']['periodType'] != 'REG'
                @head_to_head_matrix[opponent_abbrev][team_abbrev][:ot_losses] += 1
              else
                @head_to_head_matrix[opponent_abbrev][team_abbrev][:losses] += 1
              end
            elsif game['periodDescriptor'] && game['periodDescriptor']['periodType'] != 'REG'
              # We (away) lost in OT/SO
              @head_to_head_matrix[team_abbrev][opponent_abbrev][:ot_losses] += 1
              # Opponent (home) won
              @head_to_head_matrix[opponent_abbrev][team_abbrev][:wins] += 1
            else
              # We (away) lost in regulation
              @head_to_head_matrix[team_abbrev][opponent_abbrev][:losses] += 1
              # Opponent (home) won
              @head_to_head_matrix[opponent_abbrev][team_abbrev][:wins] += 1
            end
          end
        end
        
        date_range = if first_game_date && last_game_date
                      "#{first_game_date.to_s[0..9]} to #{last_game_date.to_s[0..9]}"
                    else
                      "no games"
                    end
        puts "  #{team_abbrev}: #{completed_games} completed games (#{date_range}), #{fan_matchup_games} vs fan teams"
      rescue StandardError => e
        # Log error but continue with other teams
        puts "Error fetching schedule for #{team_abbrev}: #{e.message}"
        next
      end
    end
    
    # Summary: Show matchups with high game counts for verification
    puts "\nHead-to-Head Summary (games between fan teams):"
    puts "  Note: Each game is counted once (duplicates removed from team schedules)"
    total_matchups = 0
    matchups_with_games = []
    
    @head_to_head_matrix.each do |team, opponents|
      opponents.each do |opponent, record|
        total_games = record[:wins] + record[:losses] + record[:ot_losses]
        if total_games > 0
          total_matchups += total_games
          matchups_with_games << {
            team: team,
            opponent: opponent,
            total: total_games,
            record: "#{record[:wins]}-#{record[:losses]}-#{record[:ot_losses]}"
          }
        end
      end
    end
    
    if matchups_with_games.any?
      # Sort by total games descending
      matchups_with_games.sort_by! { |m| -m[:total] }
      puts "  Top matchups by game count:"
      matchups_with_games.take(5).each do |m|
        puts "    #{m[:team]} vs #{m[:opponent]}: #{m[:record]} (#{m[:total]} games)"
      end
      puts "  Total: #{total_matchups} games counted across all matchups"
    else
      puts "  No completed games between fan teams found"
    end
  end

  # Calculate "Hall of Fame" - fans who have won the Stanley Cup in recent years
  # Winning the Stanley Cup requires 16 playoff wins (4 rounds × 4 wins per round)
  # @return [Array<Hash>, nil] Championship records or nil if none found
  def calculate_hall_of_fame
    champions = []
    current_year = Time.now.year
    
    # Get all seasons from the last N years
    fan_teams.each do |team|
      abbrev = team['teamAbbrev']['default']
      fan = @manager_team_map[abbrev]
      
      # Check each season in historical data
      history = @historical_tracker.get_fan_history(fan)
      history.each do |season, stats|
        # Parse season year (e.g., "2022-2023" -> 2023)
        season_end_year = season.split('-').last.to_i
        next unless season_end_year >= (current_year - HALL_OF_FAME_LOOKBACK_YEARS)
        
        # Stanley Cup win requires 16 playoff wins (4 rounds × 4 wins)
        playoff_wins = stats['playoff_wins'] || 0
        if playoff_wins >= STANLEY_CUP_WINS_REQUIRED
          champions << {
            fan: fan,
            team: team['teamName']['default'],
            team_abbrev: abbrev,
            season: season,
            year: season_end_year,
            value: playoff_wins,
            display: "🏆 #{season} Stanley Cup Champion (#{playoff_wins} playoff wins)"
          }
        end
      end
    end
    
    return nil if champions.empty?
    
    # Sort by year (most recent first)
    sorted = champions.sort_by { |c| -c[:year] }
    sorted.uniq { |c| [c[:fan], c[:season]] } # Remove duplicates
  end

  # Calculate "Sharks Victims" - fans who have lost to the Sharks this season
  # Shows how many times and by how many total points (goal differential)
  def calculate_sharks_victims
    calculate_team_victims('SJS', 'Sharks')
  end
  
  # Calculate "Predators Victims" - fans who have lost to the Predators this season
  # Shows how many times and by how many total points (goal differential)
  def calculate_predators_victims
    calculate_team_victims('NSH', 'Predators')
  end
  
  # Generic method to calculate victims for any team
  # @param team_abbrev [String] Team abbreviation (e.g., 'SJS', 'NSH')
  # @param team_name [String] Team name for display purposes
  # @return [Array<Hash>, nil] List of victims or nil if none
  def calculate_team_victims(team_abbrev, team_name)
    return nil if @head_to_head_matrix.nil? || @head_to_head_matrix.empty?
    
    # Check if team exists in our data
    return nil unless @head_to_head_matrix.key?(team_abbrev)
    
    victims = []
    
    # Look at all opponents the team has faced
    team_record = @head_to_head_matrix[team_abbrev]
    
    team_record.each do |opponent_abbrev, record|
      # Skip if opponent is not a fan team
      next unless @manager_team_map[opponent_abbrev] && @manager_team_map[opponent_abbrev] != 'N/A'
      
      # Get the losses from the opponent's perspective (which are team wins)
      opponent_record = @head_to_head_matrix[opponent_abbrev]
      next unless opponent_record && opponent_record[team_abbrev]
      
      opponent_stats = opponent_record[team_abbrev]
      total_losses = opponent_stats[:losses] + opponent_stats[:ot_losses]
      
      # Only include if they've actually lost to the team
      next if total_losses == 0
      
      # Find the opponent team info
      opponent_team = find_team_by_abbrev(opponent_abbrev)
      next unless opponent_team
      
      # Calculate approximate goal differential
      goal_differential = calculate_goal_differential_vs_team(opponent_abbrev, team_abbrev)
      
      victims << {
        fan: @manager_team_map[opponent_abbrev],
        team: opponent_team['teamName']['default'],
        team_abbrev: opponent_abbrev,
        losses: total_losses,
        ot_losses: opponent_stats[:ot_losses],
        reg_losses: opponent_stats[:losses],
        goal_differential: goal_differential,
        value: total_losses, # For sorting
        display: "#{total_losses} #{total_losses == 1 ? 'loss' : 'losses'} (#{goal_differential > 0 ? '+' : ''}#{goal_differential} goal diff)"
      }
    end
    
    return nil if victims.empty?
    
    # Sort by most losses descending, then by worst goal differential
    sorted = victims.sort_by { |v| [-v[:losses], v[:goal_differential]] }
    sorted
  end
  
  # Calculate goal differential for a team against another team
  # Negative means they were outscored by the opponent
  # @param team_abbrev [String] Team abbreviation to check
  # @param opponent_abbrev [String] Opponent team abbreviation
  # @return [Integer] Goal differential (positive means team outscored opponent)
  def calculate_goal_differential_vs_team(team_abbrev, opponent_abbrev)
    require 'net/http'
    require 'json'
    require 'uri'
    
    # Determine current season
    current_year = Time.now.year
    current_month = Time.now.month
    season = current_month >= 10 ? "#{current_year}#{current_year + 1}" : "#{current_year - 1}#{current_year}"
    
    total_goals_for = 0
    total_goals_against = 0
    
    begin
      # Fetch season schedule for the team
      url = URI("https://api-web.nhle.com/v1/club-schedule-season/#{team_abbrev}/#{season}")
      response = Net::HTTP.get_response(url)
      
      unless response.is_a?(Net::HTTPSuccess)
        puts "Warning: Failed to fetch schedule for #{team_abbrev}: HTTP #{response.code}"
        return 0
      end
      
      schedule_data = JSON.parse(response.body)
      games = schedule_data['games'] || []
      
      # Process each game against the opponent
      games.each do |game|
        # Check if game is completed
        game_state = game['gameState']
        is_completed = case game_state
                      when Integer
                        [3, 4, 5, 6, 7].include?(game_state)
                      when String
                        ['OFF', 'FINAL', 'OVER'].include?(game_state.upcase)
                      else
                        false
                      end
        next unless is_completed
        
        home_abbrev = game['homeTeam']['abbrev']
        away_abbrev = game['awayTeam']['abbrev']
        
        # Check if this is a game vs opponent (regular season only)
        game_id_str = game['id'].to_s
        next if game_id_str.length >= 6 && game_id_str[4..5] != '02'
        
        is_vs_opponent = (home_abbrev == opponent_abbrev && away_abbrev == team_abbrev) ||
                         (away_abbrev == opponent_abbrev && home_abbrev == team_abbrev)
        next unless is_vs_opponent
        
        home_score = game['homeTeam']['score']
        away_score = game['awayTeam']['score']
        
        if home_abbrev == team_abbrev
          # Team is home
          total_goals_for += home_score
          total_goals_against += away_score
        else
          # Team is away
          total_goals_for += away_score
          total_goals_against += home_score
        end
      end
    rescue StandardError => e
      # Return 0 if we can't fetch the data
      return 0
    end
    
    total_goals_for - total_goals_against
  end

  # Helper method to convert a number to ordinal (1st, 2nd, 3rd, etc.)
  def get_ordinal(number)
    return "" if number <= 0
    
    # Special cases for 11, 12, 13 (they use 'th')
    if [11, 12, 13].include?(number % 100)
      return "#{number}th"
    end
    
    # Check last digit for st, nd, rd
    case number % 10
    when 1 then "#{number}st"
    when 2 then "#{number}nd"
    when 3 then "#{number}rd"
    else "#{number}th"
    end
  end
end
