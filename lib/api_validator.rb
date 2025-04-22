# filepath: /workspaces/hockey_bet/lib/api_validator.rb
require 'json'
require 'logger'

class ApiValidator
  def initialize(logger = Logger.new($stdout))
    @logger = logger
  end

  # Validate teams API response against expected schema
  def validate_teams_response(response)
    return false if response.nil? || !response.is_a?(Hash) || !response.key?('standings')

    teams = response['standings']
    return false unless teams.is_a?(Array) && !teams.empty?

    # Check first team has expected structure
    team = teams.first
    required_keys = %w[teamName teamAbbrev wins losses points
                       divisionSequence wildcardSequence]

    is_valid = required_keys.all? { |key| team.key?(key) }

    # Check nested keys
    is_valid = is_valid && team['teamName'].is_a?(Hash) && team['teamName'].key?('default')
    is_valid = is_valid && team['teamAbbrev'].is_a?(Hash) && team['teamAbbrev'].key?('default')

    unless is_valid
      @logger.error('API response validation failed for teams')
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
    required_game_keys = %w[startTimeUTC awayTeam homeTeam]
    is_valid &&= required_game_keys.all? { |key| game.key?(key) }

    # Check team structure
    team_keys = %w[abbrev placeName]
    is_valid &&= team_keys.all? { |key| game['awayTeam'].key?(key) }
    is_valid &&= team_keys.all? { |key| game['homeTeam'].key?(key) }

    # Check nested keys
    is_valid = is_valid && game['awayTeam']['placeName'].is_a?(Hash) && game['awayTeam']['placeName'].key?('default')
    is_valid = is_valid && game['homeTeam']['placeName'].is_a?(Hash) && game['homeTeam']['placeName'].key?('default')

    unless is_valid
      @logger.error('API response validation failed for schedule')
      @logger.debug("Response structure: #{game.keys}") if game
    end

    is_valid
  end

  # Validate playoffs API response against expected schema
  def validate_playoffs_response(response)
    return false if response.nil? || !response.is_a?(Hash)

    # Check if we have the expected structure for playoffs data
    # This can vary depending on the endpoint we're using    # For playoff-bracket endpoint (v1/playoff-bracket/2025)
    if response.key?('bracketLogo') && response.key?('series')
      is_valid = response['series'].is_a?(Array)
      if is_valid && !response['series'].empty?
        # Check series structure
        series = response['series'].first
        is_valid = series.key?('seriesLetter') && series.key?('playoffRound') &&
                   series.key?('topSeedWins') && series.key?('bottomSeedWins')

        # Check that teams have required fields
        if is_valid && series.key?('topSeedTeam')
          team = series['topSeedTeam']
          is_valid = team.key?('id') && team.key?('abbrev') &&
                     team.key?('name') && team['name'].is_a?(Hash) &&
                     team['name'].key?('default') && team.key?('logo')
        end

        if is_valid && series.key?('bottomSeedTeam')
          team = series['bottomSeedTeam']
          is_valid = team.key?('id') && team.key?('abbrev') &&
                     team.key?('name') && team['name'].is_a?(Hash) &&
                     team['name'].key?('default') && team.key?('logo')
        end
      end

      return is_valid # For playoff-series/carousel endpoint (v1/playoff-series/carousel/20242025/)
    elsif response.key?('seasonId') && response.key?('currentRound') && response.key?('rounds')
      rounds = response['rounds']
      return false unless rounds.is_a?(Array)

      # Empty playoff data is valid during off-season
      return true if rounds.empty?

      # Check first round has expected structure
      round = rounds.first
      is_valid = round.key?('roundNumber') && round.key?('roundLabel') &&
                 round.key?('roundAbbrev') && round.key?('series') &&
                 round['series'].is_a?(Array)

      # Check series structure if present
      if is_valid && !round['series'].empty?
        series = round['series'].first
        is_valid = series.key?('seriesLetter') && series.key?('roundNumber') &&
                   series.key?('seriesLabel') && series.key?('seriesLink') &&
                   series.key?('topSeed') && series.key?('bottomSeed') &&
                   series.key?('neededToWin')

        # Check team structure
        if is_valid
          %w[topSeed bottomSeed].each do |team_key|
            team = series[team_key]
            next unless team

            is_valid = is_valid && team.key?('id') && team.key?('abbrev') &&
                       team.key?('wins') && team.key?('logo')
          end
        end
      end

      return is_valid
    # For schedule/playoff-series endpoint (v1/schedule/playoff-series/20242025/a)
    elsif response.key?('round') && response.key?('seriesLetter') && response.key?('games')
      is_valid = response['games'].is_a?(Array)
      if is_valid && response.key?('topSeedTeam') && response.key?('bottomSeedTeam')
        is_valid = response['topSeedTeam'].is_a?(Hash) && response['bottomSeedTeam'].is_a?(Hash)
      end

      return is_valid
    # For standings/playoffs endpoint
    elsif response.key?('rounds')
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

          # Validate additional team fields based on NHL API Reference
          if is_valid
            team_additional_keys = %w[seed seriesWins teamName]
            team_additional_valid = team_additional_keys.all? { |key| team.key?(key) }
            unless team_additional_valid
              @logger.debug("Team additional fields validation: #{team_additional_valid}")
            end
          end
        end

        # Check games array if present
        if is_valid && series.key?('games') && series['games'].is_a?(Array) && !series['games'].empty?
          game = series['games'].first
          game_required_keys = %w[gameDate gameNumber gameState]
          game_valid = game_required_keys.all? { |key| game.key?(key) }
          @logger.debug("Game fields validation: #{game_valid}") unless game_valid
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
          required_keys = %w[seriesCode seriesStatus matchupTeams]
          is_valid = required_keys.all? { |key| series.key?(key) }

          if is_valid && series['matchupTeams'].is_a?(Array) && !series['matchupTeams'].empty?
            team = series['matchupTeams'].first
            is_valid = team.key?('teamAbbrev')

            # Check additional team fields for richer validation
            if is_valid && team.key?('teamName')
              is_valid = team['teamName'].is_a?(Hash) && team['teamName'].key?('default')
            end

            # Validate seriesWins field which is crucial for playoff display
            if is_valid && !team.key?('seriesWins')
              @logger.warn('Team missing seriesWins field in playoff data')
            end
          end

          # Check games array in the new format
          if is_valid && series.key?('games') && series['games'].is_a?(Array) && !series['games'].empty?
            game = series['games'].first
            # These fields are based on the NHL API Reference
            game_required_keys = %w[gameDate gameNumber gameState awayTeam homeTeam]
            game_valid = game_required_keys.all? { |key| game.key?(key) }
            @logger.debug("Game fields validation in new format: #{game_valid}") unless game_valid
          end
        end
      end

      # Check for season information which should be present in playoff data
      if is_valid && response.key?('season')
        season_valid = response['season'].is_a?(String) && response['season'].length == 8
        @logger.debug("Season format validation: #{season_valid}") unless season_valid
      end
    elsif response.key?('id') && response['id'] == 1 && response.key?('name') && response['name'] == 'Playoffs'
      # Check for legacy format that might still be returned by some endpoints
      is_valid = response.key?('season') && response.key?('defaultRound')
      # This is likely the older format, still partially valid
      @logger.warn('Found legacy playoff format - partial validation only')
    else
      # Neither expected structure found
      is_valid = false
    end

    unless is_valid
      @logger.error('API response validation failed for playoffs')
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
        { 'standings' => [] }
      when 'schedule'
        { 'gameWeek' => [] }
      when 'playoffs'
        { 'rounds' => [] }
      else
        {}
      end
    end
  end
end
