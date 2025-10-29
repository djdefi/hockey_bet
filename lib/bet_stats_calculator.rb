# filepath: /home/runner/work/hockey_bet/hockey_bet/lib/bet_stats_calculator.rb
require 'csv'
require 'set'

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

  # Calculate top 3 fans with most wins (handles ties at medal positions)
  def calculate_top_winners
    all_stats = fan_teams
      .map { |team| create_fan_stat(team, team['wins'] || 0) }
      .sort_by { |stat| -stat[:value] }
    
    filter_top_positions(all_stats)
  end

  # Calculate top 3 fans with most losses (handles ties at medal positions)
  def calculate_top_losers
    all_stats = fan_teams
      .map { |team| create_fan_stat(team, team['losses'] || 0) }
      .sort_by { |stat| -stat[:value] }
    
    filter_top_positions(all_stats)
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
end
