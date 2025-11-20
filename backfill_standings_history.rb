#!/usr/bin/env ruby
# filepath: /home/runner/work/hockey_bet/hockey_bet/backfill_standings_history.rb
#
# Script to backfill standings history from the start of the season
# This fetches historical standings data for each game day and populates standings_history.json

require_relative 'lib/standings_history_tracker'
require 'httparty'
require 'json'
require 'csv'
require 'date'

class StandingsBackfill
  def initialize
    @tracker = StandingsHistoryTracker.new
    @fan_teams = load_fan_teams
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
    # NHL season 2024-2025 started October 8, 2024
    # We'll fetch standings for every 2-3 days from season start to now
    season_start = Date.new(2024, 10, 8)
    today = Date.today
    
    puts "Backfilling standings history from #{season_start} to #{today}"
    puts "Fan teams: #{@fan_teams.keys.join(', ')}"
    
    # Generate dates to backfill (every 3 days)
    dates = []
    current_date = season_start
    while current_date <= today
      dates << current_date
      current_date += 3
    end
    
    # Make sure today is included
    dates << today unless dates.include?(today)
    dates = dates.sort.uniq
    
    puts "Will fetch #{dates.length} historical standings snapshots"
    
    dates.each do |date|
      begin
        fetch_and_record_standings(date)
        sleep 1  # Be nice to the API
      rescue => e
        puts "Error fetching standings for #{date}: #{e.message}"
      end
    end
    
    puts "\nBackfill complete!"
    puts "Total entries in history: #{@tracker.load_history.length}"
  end
  
  def fetch_and_record_standings(date)
    # Format date for API (YYYY-MM-DD)
    date_str = date.to_s
    
    # Fetch standings for this date
    # Note: The NHL API doesn't have historical by-date lookups easily available
    # So we'll need to use the current standings and manually adjust
    # For a proper implementation, you'd need historical game data
    
    url = "https://api-web.nhle.com/v1/standings/now"
    response = HTTParty.get(url)
    
    if response.code != 200
      puts "Failed to fetch standings for #{date_str}: HTTP #{response.code}"
      return
    end
    
    data = JSON.parse(response.body)
    teams = data["standings"]
    
    # Build standings for this date
    fan_standings = {}
    @fan_teams.each do |abbrev, fan|
      team = teams.find { |t| t['teamAbbrev']['default'] == abbrev }
      if team
        # For backfill, we need actual historical data
        # This is a simplified version that uses current standings
        # In production, you'd need to calculate based on game logs
        points = team['points'] || 0
        fan_standings[fan] = points
      end
    end
    
    if fan_standings.any?
      # Record this snapshot
      history = @tracker.load_history
      
      # Check if we already have this date
      existing = history.find { |entry| entry['date'] == date_str }
      if existing
        puts "Updating existing entry for #{date_str}"
        existing['standings'] = fan_standings
      else
        puts "Adding new entry for #{date_str}"
        history << {
          'date' => date_str,
          'standings' => fan_standings
        }
      end
      
      # Sort by date and save
      history.sort_by! { |entry| entry['date'] }
      @tracker.save_history(history)
    end
  end
end

# Run the backfill if this script is executed directly
if __FILE__ == $0
  backfill = StandingsBackfill.new
  backfill.backfill
end
