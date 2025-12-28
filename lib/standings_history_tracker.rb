# filepath: /home/runner/work/hockey_bet/hockey_bet/lib/standings_history_tracker.rb
require 'json'
require 'fileutils'
require 'date'
require_relative 'base_tracker'

# StandingsHistoryTracker manages historical standings data for the fan league
# Tracks comprehensive team statistics over time to enable:
# - Points and win/loss trends
# - Goal differential analysis
# - Division rankings history
# - Season-based filtering
class StandingsHistoryTracker
  include BaseTracker
  
  # Maximum days of history to retain (prevents unbounded growth)
  MAX_HISTORY_DAYS = 365
  
  # Minimum entries to keep regardless of age (ensures chart functionality)
  MIN_HISTORY_ENTRIES = 7
  
  def initialize(data_file = 'data/standings_history.json', verbose: true)
    # Initialize with empty array as default (history is an array, not a hash)
    initialize_tracker(data_file, verbose: verbose, default_content: [])
  end
  
  # Load standings history from JSON file
  # @return [Array<Hash>] Array of daily standings entries
  def load_history
    load_data_safe([])
  end
  
  # Save standings history to JSON file
  # @param data [Array<Hash>] Standings history data
  def save_history(data)
    save_data_safe(data)
  end
  
  # Record current standings for all fans
  # @param manager_team_map [Hash] Map of team abbreviations to fan names
  # @param teams [Array<Hash>] Array of team data from NHL API
  def record_current_standings(manager_team_map, teams)
    history = load_history
    
    # Get today's date in ISO format
    today = Date.today.to_s
    current_season = determine_season(Date.today)
    
    # Check if we already have an entry for today
    today_entry = history.find { |entry| entry['date'] == today }
    
    # Build the standings for today with enhanced stats
    fan_standings = build_fan_standings(manager_team_map, teams)
    
    if today_entry
      # Update existing entry for today
      today_entry['standings'] = fan_standings
      today_entry['season'] = current_season
    else
      # Add new entry for today
      history << {
        'date' => today,
        'season' => current_season,
        'standings' => fan_standings
      }
    end
    
    # Prune old entries while maintaining minimum for charts
    history = prune_history(history)
    
    # Sort by date to ensure chronological order
    history.sort_by! { |entry| entry['date'] }
    
    save_history(history)
    
    log_info("Standings history updated: #{fan_standings.size} fans tracked for #{today}")
  end
  
  # Get history filtered by season
  def get_history_by_season(season)
    history = load_history
    history.select { |entry| (entry['season'] || determine_season(Date.parse(entry['date']))) == season }
  end
  
  # Backfill season information for existing entries that don't have it
  # @return [Boolean] True if any entries were updated
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
    log_info("Season information backfilled for #{history.length} entries") if changed
    changed
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
  
  # Build fan standings from team data
  # @param manager_team_map [Hash] Map of team abbreviations to fan names
  # @param teams [Array<Hash>] Array of team data from NHL API
  # @return [Hash] Fan standings with comprehensive stats
  def build_fan_standings(manager_team_map, teams)
    fan_standings = {}
    
    manager_team_map.each do |team_abbrev, fan_name|
      next if fan_name == "N/A"
      
      # Find the team in the teams array
      team = teams.find { |t| t['teamAbbrev']['default'] == team_abbrev }
      next unless team
      
      # Store comprehensive team stats for chart visualizations
      fan_standings[fan_name] = {
        'points' => team['points'] || 0,
        'wins' => team['wins'] || 0,
        'losses' => team['losses'] || 0,
        'ot_losses' => team['otLosses'] || 0,
        'games_played' => team['gamesPlayed'] || 0,
        'goals_for' => team['goalFor'] || 0,
        'goals_against' => team['goalAgainst'] || 0,
        'goal_diff' => (team['goalFor'] || 0) - (team['goalAgainst'] || 0),
        'division_rank' => team['divisionSequence'] || 0,
        'conference_rank' => team['conferenceSequence'] || 0
      }
    end
    
    fan_standings
  end
  
  # Prune history to keep file size manageable
  # @param history [Array<Hash>] History entries
  # @return [Array<Hash>] Pruned history
  def prune_history(history)
    cutoff_date = (Date.today - MAX_HISTORY_DAYS).to_s
    history_after_cutoff = history.select { |entry| entry['date'] >= cutoff_date }
    
    # If we have enough recent data, use it. Otherwise, keep the older data.
    if history_after_cutoff.length >= MIN_HISTORY_ENTRIES
      history_after_cutoff
    elsif history.length > MIN_HISTORY_ENTRIES
      # Keep the most recent entries even if they're old
      history.last(MIN_HISTORY_ENTRIES)
    else
      history
    end
  end
  
  # Determine season from a date
  # NHL season typically runs from October to June (e.g., 2024-10 to 2025-06)
  # Off-season months (July-September) are considered part of the upcoming season
  # @param date [Date] Date to determine season for
  # @return [String] Season identifier (e.g., "2024-2025")
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
end
