# filepath: /home/runner/work/hockey_bet/hockey_bet/lib/fan_league_constants.rb

# FanLeagueConstants provides shared constants for the hockey fan league
# Used across prediction, standings, and leaderboard features
module FanLeagueConstants
  # The 13 fans in the hockey league (honor system, no authentication)
  FAN_NAMES = [
    'Jeff C.',
    'Ryan T.',
    'Keith R.',
    'Mike M.',
    'Zak S.',
    'Travis R.',
    'Sean R.',
    'Brian D.',
    'Tyler F.',
    'Ryan B.',
    'Trevor R.',
    'Dan R.',
    'David K.'
  ].freeze
  
  # Season configuration
  SEASON_START_MONTH = 7  # July (off-season begins)
  SEASON_END_MONTH = 6    # June (season ends)
  
  # Data file paths
  DATA_DIR = 'data'
  PREDICTIONS_FILE = "#{DATA_DIR}/predictions.json"
  PREDICTION_RESULTS_FILE = "#{DATA_DIR}/prediction_results.json"
  STANDINGS_HISTORY_FILE = "#{DATA_DIR}/standings_history.json"
  
  # Validation method
  # @param fan_name [String] Name to validate
  # @return [Boolean] True if fan name is valid
  def self.valid_fan_name?(fan_name)
    FAN_NAMES.include?(fan_name)
  end
  
  # Get current season identifier (e.g., "2024-2025")
  # @param date [Date] Date to determine season for (defaults to today)
  # @return [String] Season identifier
  def self.current_season(date = Date.today)
    year = date.year
    month = date.month
    
    # Months 1-6: season started previous year (e.g., Jan 2025 is 2024-2025 season)
    # Months 7-12: season starts this year (e.g., Oct 2024 is 2024-2025 season)
    if month >= SEASON_START_MONTH
      "#{year}-#{year + 1}"
    else
      "#{year - 1}-#{year}"
    end
  end
end
