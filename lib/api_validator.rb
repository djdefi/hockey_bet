# filepath: /workspaces/hockey_bet/lib/api_validator.rb
require 'json'
require 'logger'

# ApiValidator ensures NHL API responses match expected schema
# This helps detect breaking changes in the API and provides early warning
# when the data structure changes, preventing silent failures
class ApiValidator
  # Initializes validator with optional custom logger
  # @param logger [Logger] Logger instance for validation messages
  def initialize(logger = Logger.new(STDOUT))
    @logger = logger
  end

  # Validate teams API response against expected schema
  # @param response [Hash] API response from NHL teams endpoint
  # @return [Boolean] True if response is valid, false otherwise
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
  # @param response [Hash] API response from NHL schedule endpoint
  # @return [Boolean] True if response is valid, false otherwise
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

  # Validate playoffs API response against expected schema
  def validate_playoffs_response(response)
    return false if response.nil? || !response.is_a?(Hash)

    # Check if we have the expected structure for playoffs data
    # This can vary depending on whether we're using the standings/playoffs or playoffs/now endpoint

    # For standings/playoffs endpoint
    if response.key?('rounds')
      rounds = response['rounds']
      return false unless rounds.is_a?(Array)

      # Empty playoff data is valid during off-season
      return true if rounds.empty?

      # Check first round has expected structure
      round = rounds.first
      is_valid = round.key?('roundNumber') && round.key?('names') && round.key?('series')
      is_valid = is_valid && round['series'].is_a?(Array) && !round['series'].empty?

      if is_valid
        # Check series structure
        series = round['series'].first
        is_valid = series.key?('matchupTeams') && series['matchupTeams'].is_a?(Array)

        # Check team structure if there are teams in the series
        if is_valid && !series['matchupTeams'].empty?
          team = series['matchupTeams'].first
          is_valid = team.key?('teamAbbrev') && team['teamAbbrev'].is_a?(Hash) && team['teamAbbrev'].key?('default')
        end
      end
    # For playoffs/now endpoint
    elsif response.key?('currentRound') || response.key?('playoffRounds')
      is_valid = true

      if response.key?('playoffRounds') && response['playoffRounds'].is_a?(Array) && !response['playoffRounds'].empty?
        round = response['playoffRounds'].first
        is_valid = round.key?('round') && round.key?('series') && round['series'].is_a?(Array)

        if is_valid && !round['series'].empty?
          series = round['series'].first
          required_keys = ['seriesCode', 'seriesStatus', 'matchupTeams']
          is_valid = required_keys.all? { |key| series.key?(key) }

          if is_valid && series['matchupTeams'].is_a?(Array) && !series['matchupTeams'].empty?
            team = series['matchupTeams'].first
            is_valid = team.key?('teamAbbrev')
          end
        end
      end
    else
      # Neither expected structure found
      is_valid = false
    end

    unless is_valid
      @logger.error("API response validation failed for playoffs")
      @logger.debug("Response structure: #{response.keys}")
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
      when 'playoffs'
        {'rounds' => []}
      else
        {}
      end
    end
  end
end
