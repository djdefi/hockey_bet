# Process data from the playoff-bracket endpoint format
def process_playoff_data_bracket_format
  return unless @playoff_data['series']

  @playoff_rounds = []

  # Group series by playoff round
  rounds_data = @playoff_data['series'].group_by { |series| series['playoffRound'] }

  # Process each round
  rounds_data.sort.each do |round_number, series_list|
    round_data = {
      number: round_number,
      name: get_round_name(round_number),
      series: []
    }

    # Process each series in this round
    series_list.each do |series|
      # Skip placeholder series without teams
      next unless series['topSeedTeam'] && series['bottomSeedTeam']

      # Format the series data
      series_data = {
        letter: series['seriesLetter'],
        top_seed: {
          name: series['topSeedTeam']['name']['default'],
          abbrev: series['topSeedTeam']['abbrev'],
          logo: series['topSeedTeam']['logo'],
          wins: series['topSeedWins']
        },
        bottom_seed: {
          name: series['bottomSeedTeam']['name']['default'],
          abbrev: series['bottomSeedTeam']['abbrev'],
          logo: series['bottomSeedTeam']['logo'],
          wins: series['bottomSeedWins']
        },
        games: [] # The bracket endpoint doesn't include individual games
      }

      round_data[:series] << series_data
    end

    @playoff_rounds << round_data
  end

  # Sort rounds by number
  @playoff_rounds.sort_by! { |round| round[:number] }
end

# Process data from the playoff-series carousel endpoint format
def process_playoff_data_carousel_format
  return unless @playoff_data['rounds']

  @playoff_rounds = []

  # Process each round
  @playoff_data['rounds'].each do |round|
    round_data = {
      number: round['roundNumber'],
      name: round['roundLabel'] || get_round_name(round['roundNumber']),
      series: []
    }

    # Process each series in this round
    round['series'].each do |series|
      # Format the series data
      series_data = {
        letter: series['seriesLetter'],
        top_seed: {
          name: series['topSeed']['abbrev'], # Using abbrev as name is often missing
          abbrev: series['topSeed']['abbrev'],
          logo: series['topSeed']['logo'],
          wins: series['topSeed']['wins']
        },
        bottom_seed: {
          name: series['bottomSeed']['abbrev'], # Using abbrev as name is often missing
          abbrev: series['bottomSeed']['abbrev'],
          logo: series['bottomSeed']['logo'],
          wins: series['bottomSeed']['wins']
        },
        games: [] # The carousel endpoint doesn't include individual games
      }

      round_data[:series] << series_data
    end

    @playoff_rounds << round_data
  end

  # Sort rounds by number
  @playoff_rounds.sort_by! { |round| round[:number] }
end

# Process data from the schedule/playoff-series endpoint format
def process_playoff_data_series_format
  unless @playoff_data['games'] && @playoff_data['topSeedTeam'] && @playoff_data['bottomSeedTeam']
    return
  end

  # For this endpoint, we only get data for a single series, so create a single round
  round_data = {
    number: @playoff_data['round'] || 1,
    name: @playoff_data['roundLabel'] || get_round_name(@playoff_data['round'] || 1),
    series: []
  }

  # Format the series data
  series_data = {
    letter: @playoff_data['seriesLetter'],
    top_seed: {
      name: @playoff_data['topSeedTeam']['name']['default'],
      abbrev: @playoff_data['topSeedTeam']['abbrev'],
      logo: @playoff_data['topSeedTeam']['logo'] || @playoff_data['topSeedTeam']['darkLogo'],
      wins: @playoff_data['topSeedTeam']['seriesWins']
    },
    bottom_seed: {
      name: @playoff_data['bottomSeedTeam']['name']['default'],
      abbrev: @playoff_data['bottomSeedTeam']['abbrev'],
      logo: @playoff_data['bottomSeedTeam']['logo'] || @playoff_data['bottomSeedTeam']['darkLogo'],
      wins: @playoff_data['bottomSeedTeam']['seriesWins']
    },
    games: []
  }

  # Process each game in the series
  @playoff_data['games'].each do |game|
    game_data = {
      number: game['gameNumber'],
      status: game['gameState'],
      start_time: game['startTimeUTC'],
      home_team: game['homeTeam']['abbrev'],
      away_team: game['awayTeam']['abbrev'],
      home_score: game['homeTeam']['score'],
      away_score: game['awayTeam']['score']
    }

    series_data[:games] << game_data
  end

  round_data[:series] << series_data
  @playoff_rounds << round_data
end

# Helper method to get round name based on round number
def get_round_name(round_number)
  case round_number.to_i
  when 1
    'First Round'
  when 2
    'Second Round'
  when 3
    'Conference Finals'
  when 4
    'Stanley Cup Finals'
  else
    "Round #{round_number}"
  end
end
