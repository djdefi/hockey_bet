# filepath: /workspaces/hockey_bet/lib/api_validator.rb
require 'json'
require 'logger'

class ApiValidator
  def initialize(logger = Logger.new(STDOUT))
    @logger = logger
  end

  # Validate teams API response against expected schema
  def validate_teams_response(response)
    return false if response.nil? || !response.is_a?(Hash) || !response.key?('standings')
    
    teams = response['standings']
    return false unless teams.is_a?(Array) && !teams.empty?
    
    # Check first team has expected structure
    team = teams.first
    required_keys = ['teamName', 'teamAbbrev', 'wins', 'losses', 'points', 
                    'divisionSequence', 'wildcardSequence']
                    
    is_valid = required_keys.all? { |key| team.key?(key) }
    
    # Check nested keys
    is_valid = is_valid && team['teamName'].is_a?(Hash) && team['teamName'].key?('default')
    is_valid = is_valid && team['teamAbbrev'].is_a?(Hash) && team['teamAbbrev'].key?('default')
    
    unless is_valid
      @logger.error("API response validation failed for teams")
      @logger.debug("Response structure: #{teams.first.keys}")
    end
    
    is_valid
  end

  # Validate schedule API response against expected schema
  def validate_schedule_response(response)
    return false if response.nil? || !response.is_a?(Hash) || !response.key?('gameWeek')
    
    game_week = response['gameWeek']
    return false unless game_week.is_a?(Array)
    
    # If no games, that's ok (off-season)
    return true if game_week.empty?
    
    # Check first day has expected structure
    day = game_week.first
    is_valid = day.key?('date') && day.key?('games') && day['games'].is_a?(Array)
    
    # If no games on first day, check another day
    if day['games'].empty?
      non_empty_day = game_week.find { |d| !d['games'].empty? }
      return true unless non_empty_day # All days empty is valid (off-season)
      day = non_empty_day
    end
    
    # Check game structure
    game = day['games'].first
    required_game_keys = ['startTimeUTC', 'awayTeam', 'homeTeam']
    is_valid = is_valid && required_game_keys.all? { |key| game.key?(key) }
    
    # Check team structure
    team_keys = ['abbrev', 'placeName']
    is_valid = is_valid && team_keys.all? { |key| game['awayTeam'].key?(key) }
    is_valid = is_valid && team_keys.all? { |key| game['homeTeam'].key?(key) }
    
    # Check nested keys
    is_valid = is_valid && game['awayTeam']['placeName'].is_a?(Hash) && game['awayTeam']['placeName'].key?('default')
    is_valid = is_valid && game['homeTeam']['placeName'].is_a?(Hash) && game['homeTeam']['placeName'].key?('default')
    
    unless is_valid
      @logger.error("API response validation failed for schedule")
      @logger.debug("Response structure: #{game.keys}") if game
    end
    
    is_valid
  end
  
  # Handle API response failures with graceful fallbacks
  def handle_api_failure(api_name, fallback_data_path = nil)
    @logger.error("#{api_name} API failed, using fallback data")
    
    if fallback_data_path && File.exist?(fallback_data_path)
      begin
        JSON.parse(File.read(fallback_data_path))
      rescue JSON::ParserError => e
        @logger.error("Error parsing fallback data: #{e.message}")
        {}
      end
    else
      # Return empty structure based on API type
      case api_name
      when 'teams'
        {'standings' => []}
      when 'schedule'
        {'gameWeek' => []}
      else
        {}
      end
    end
  end
end
