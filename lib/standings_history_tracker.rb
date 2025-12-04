# filepath: /home/runner/work/hockey_bet/hockey_bet/lib/standings_history_tracker.rb
require 'json'
require 'fileutils'
require 'date'

class StandingsHistoryTracker
  attr_reader :data_file
  
  def initialize(data_file = 'data/standings_history.json')
    @data_file = data_file
    ensure_data_file_exists
  end
  
  # Load standings history from JSON file
  def load_history
    return [] unless File.exist?(@data_file)
    
    JSON.parse(File.read(@data_file))
  rescue JSON::ParserError => e
    puts "Warning: Error parsing standings history: #{e.message}"
    []
  end
  
  # Save standings history to JSON file
  def save_history(data)
    FileUtils.mkdir_p(File.dirname(@data_file))
    File.write(@data_file, JSON.pretty_generate(data))
  end
  
  # Record current standings for all fans
  def record_current_standings(manager_team_map, teams)
    history = load_history
    
    # Get today's date in ISO format
    today = Date.today.to_s
    current_season = determine_season(Date.today)
    
    # Check if we already have an entry for today
    today_entry = history.find { |entry| entry['date'] == today }
    
    # Build the standings for today
    fan_points = {}
    manager_team_map.each do |team_abbrev, fan_name|
      next if fan_name == "N/A"
      
      # Find the team in the teams array
      team = teams.find { |t| t['teamAbbrev']['default'] == team_abbrev }
      next unless team
      
      fan_points[fan_name] = team['points'] || 0
    end
    
    if today_entry
      # Update existing entry for today
      today_entry['standings'] = fan_points
      today_entry['season'] = current_season
    else
      # Add new entry for today
      history << {
        'date' => today,
        'season' => current_season,
        'standings' => fan_points
      }
    end
    
    # Keep only last 365 days of data to prevent file from growing too large
    # However, keep at least 7 entries to ensure trends chart has enough data points
    cutoff_date = (Date.today - 365).to_s
    history_after_cutoff = history.select { |entry| entry['date'] >= cutoff_date }
    
    # If we have enough recent data, use it. Otherwise, keep the older data.
    if history_after_cutoff.length >= 7
      history = history_after_cutoff
    elsif history.length > 7
      # Keep the most recent 7 entries even if they're old
      history = history.last(7)
    end
    
    # Sort by date to ensure chronological order
    history.sort_by! { |entry| entry['date'] }
    
    save_history(history)
    
    puts "Standings history updated: #{fan_points.size} fans tracked for #{today}"
  end
  
  # Get history filtered by season
  def get_history_by_season(season)
    history = load_history
    history.select { |entry| (entry['season'] || determine_season(Date.parse(entry['date']))) == season }
  end
  
  # Backfill season information for existing entries that don't have it
  def backfill_seasons
    history = load_history
    changed = false
    
    history.each do |entry|
      unless entry['season']
        entry['season'] = determine_season(Date.parse(entry['date']))
        changed = true
      end
    end
    
    save_history(history) if changed
    puts "Season information backfilled for #{history.length} entries" if changed
  end
  
  # Get all available seasons from history
  def get_available_seasons
    history = load_history
    seasons = history.map { |entry| entry['season'] || determine_season(Date.parse(entry['date'])) }.uniq.compact
    seasons.sort.reverse # Most recent first
  end
  
  # Get current season identifier (e.g., "2024-2025")
  def current_season
    determine_season(Date.today)
  end
  
  private
  
  # Determine season from a date
  # NHL season typically runs from October to June (e.g., 2024-10 to 2025-06)
  # Off-season months (July-September) are considered part of the upcoming season
  def determine_season(date)
    year = date.year
    month = date.month
    
    # Months 1-6: season started previous year (e.g., Jan 2025 is 2024-2025 season)
    # Months 7-12: season starts this year (e.g., Oct 2024 is 2024-2025 season)
    if month >= 7
      "#{year}-#{year + 1}"
    else
      "#{year - 1}-#{year}"
    end
  end
  
  def ensure_data_file_exists
    return if File.exist?(@data_file)
    
    FileUtils.mkdir_p(File.dirname(@data_file))
    save_history([])
  end
end
