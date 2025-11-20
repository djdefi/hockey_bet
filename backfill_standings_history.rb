#!/usr/bin/env ruby
# filepath: /home/runner/work/hockey_bet/hockey_bet/backfill_standings_history.rb
#
# Script to backfill standings history from the start of the season
# This fetches historical game data and reconstructs standings for each date

require_relative 'lib/standings_history_tracker'
require 'httparty'
require 'json'
require 'csv'
require 'date'

class StandingsBackfill
  def initialize
    @tracker = StandingsHistoryTracker.new
    @fan_teams = load_fan_teams
    @season = '20242025'
  end
  
  def load_fan_teams
    # Load fan to team mapping
    mapping = {}
    CSV.foreach('fan_team.csv', headers: true) do |row|
      fan = row['fan']
      team = row['team'].strip
      # Map team names to abbreviations
      abbrev = case team.downcase
      when 'sharks' then 'SJS'
      when 'predators' then 'NSH'
      when 'avalanche' then 'COL'
      when 'ducks' then 'ANA'
      when 'devils' then 'NJD'
      when 'knights' then 'VGK'
      when 'sabres' then 'BUF'
      when 'wild' then 'MIN'
      when 'kings' then 'LAK'
      when 'utah' then 'UTA'
      when 'kraken' then 'SEA'
      when 'capitals' then 'WSH'
      when 'jets' then 'WPG'
      else
        puts "Warning: Unknown team '#{team}' for fan #{fan}"
        nil
      end
      mapping[abbrev] = fan if abbrev
    end
    mapping
  end
  
  def backfill
    puts "Backfilling standings history for #{@season} season"
    puts "Fan teams: #{@fan_teams.keys.join(', ')}"
    
    # Fetch all games for all fan teams
    puts "\nFetching game schedules for all teams..."
    all_games = fetch_all_team_games
    
    # Build points timeline
    puts "\nCalculating historical points..."
    points_by_date = calculate_points_timeline(all_games)
    
    # Create snapshots every 3 days
    puts "\nCreating historical snapshots..."
    create_snapshots(points_by_date)
    
    puts "\nBackfill complete!"
    puts "Total entries in history: #{@tracker.load_history.length}"
  end
  
  def fetch_all_team_games
    all_games = {}
    
    @fan_teams.keys.each do |team_abbrev|
      print "Fetching #{team_abbrev}... "
      url = "https://api-web.nhle.com/v1/club-schedule-season/#{team_abbrev}/#{@season}"
      
      begin
        response = HTTParty.get(url, timeout: 10)
        
        if response.code == 200
          data = JSON.parse(response.body)
          # Regular season only, and only completed games
          games = data['games'].select do |g|
            g['gameType'] == 2 && 
            g['gameState'] == 'OFF' &&  # Game is over
            g['gameOutcome']  # Has an outcome
          end
          all_games[team_abbrev] = games
          puts "#{games.length} completed games"
        else
          puts "Failed (HTTP #{response.code})"
          all_games[team_abbrev] = []
        end
      rescue => e
        puts "Error: #{e.message}"
        all_games[team_abbrev] = []
      end
      
      sleep 0.5  # Be nice to the API
    end
    
    all_games
  end
  
  def calculate_points_timeline(all_games)
    # Build a timeline of points for each team
    points_by_date = {}
    today = Date.today
    
    @fan_teams.each do |team_abbrev, fan_name|
      games = all_games[team_abbrev] || []
      cumulative_points = 0
      
      games.sort_by { |g| g['gameDate'] }.each do |game|
        next unless game['gameOutcome']
        
        game_date = Date.parse(game['gameDate'])
        
        # Skip future games (API might have test data)
        next if game_date > today
        
        # Calculate points from this game
        outcome = game['gameOutcome']['lastPeriodType']
        points_earned = case outcome
        when 'REG'
          # Check if we won or lost
          home_team = game['homeTeam']['abbrev']
          away_team = game['awayTeam']['abbrev']
          our_score = home_team == team_abbrev ? game['homeTeam']['score'] : game['awayTeam']['score']
          their_score = home_team == team_abbrev ? game['awayTeam']['score'] : game['homeTeam']['score']
          
          if our_score > their_score
            2  # Win in regulation
          else
            0  # Loss in regulation
          end
        when 'OT', 'SO'
          # Overtime/Shootout
          home_team = game['homeTeam']['abbrev']
          away_team = game['awayTeam']['abbrev']
          our_score = home_team == team_abbrev ? game['homeTeam']['score'] : game['awayTeam']['score']
          their_score = home_team == team_abbrev ? game['awayTeam']['score'] : game['homeTeam']['score']
          
          if our_score > their_score
            2  # Win in OT/SO
          else
            1  # Loss in OT/SO (loser point)
          end
        else
          0
        end
        
        cumulative_points += points_earned
        
        # Store points for this date
        points_by_date[game_date] ||= {}
        points_by_date[game_date][fan_name] = cumulative_points
      end
    end
    
    points_by_date
  end
  
  def create_snapshots(points_by_date)
    return if points_by_date.empty?
    
    # Get all dates and sort them
    all_dates = points_by_date.keys.sort
    season_start = all_dates.first
    today = Date.today
    season_end = [all_dates.last, today].min  # Don't go past today
    
    puts "Season date range: #{season_start} to #{season_end}"
    
    # Create snapshots every 3 days
    history = []
    current_points = {}  # Track latest known points for each fan
    
    snapshot_date = season_start
    while snapshot_date <= season_end
      # Update current points with any games played up to this date
      points_by_date.each do |game_date, fan_points|
        if game_date <= snapshot_date
          fan_points.each do |fan, points|
            current_points[fan] = points
          end
        end
      end
      
      # Only create snapshot if we have data
      if current_points.any?
        history << {
          'date' => snapshot_date.to_s,
          'standings' => current_points.dup
        }
        puts "  #{snapshot_date}: #{current_points.values.max || 0} max points"
      end
      
      snapshot_date += 3
    end
    
    # Add final snapshot for today if not already included
    if !history.empty? && history.last['date'] != today.to_s
      # Update with all games up to today
      points_by_date.each do |game_date, fan_points|
        if game_date <= today
          fan_points.each do |fan, points|
            current_points[fan] = points
          end
        end
      end
      
      history << {
        'date' => today.to_s,
        'standings' => current_points.dup
      }
      puts "  #{today}: #{current_points.values.max || 0} max points (today)"
    end
    
    # Save to file
    @tracker.save_history(history)
  end
end

# Run the backfill if this script is executed directly
if __FILE__ == $0
  backfill = StandingsBackfill.new
  backfill.backfill
end
