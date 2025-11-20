# filepath: /home/runner/work/hockey_bet/hockey_bet/lib/standings_history_tracker.rb
require 'json'
require 'fileutils'
require 'date'

class StandingsHistoryTracker
  attr_reader :data_file
  
  def initialize(data_file = '_site/standings_history.json')
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
    else
      # Add new entry for today
      history << {
        'date' => today,
        'standings' => fan_points
      }
    end
    
    # Keep only last 365 days of data to prevent file from growing too large
    cutoff_date = (Date.today - 365).to_s
    history.select! { |entry| entry['date'] >= cutoff_date }
    
    # Sort by date to ensure chronological order
    history.sort_by! { |entry| entry['date'] }
    
    save_history(history)
    
    puts "Standings history updated: #{fan_points.size} fans tracked for #{today}"
  end
  
  private
  
  def ensure_data_file_exists
    return if File.exist?(@data_file)
    
    FileUtils.mkdir_p(File.dirname(@data_file))
    save_history([])
  end
end
