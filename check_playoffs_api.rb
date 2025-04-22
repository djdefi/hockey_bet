#!/usr/bin/env ruby
require_relative 'lib/api_validator'
require 'logger'

# Create a logger
logger = Logger.new($stdout)
logger.level = Logger::INFO

# Initialize the validator
validator = ApiValidator.new(logger)

puts '===== Testing NHL Playoff API Format Validation ====='

# Test playoff bracket format
puts "\n1. Testing playoff-bracket format"
bracket_response = {
  'bracketLogo' => 'https://assets.nhle.com/logos/playoffs/png/scp-20242025-horizontal-banner-en.png',
  'series' => [
    {
      'seriesLetter' => 'A',
      'playoffRound' => 1,
      'topSeedWins' => 1,
      'bottomSeedWins' => 0,
      'topSeedTeam' => {
        'id' => 10,
        'abbrev' => 'TOR',
        'name' => { 'default' => 'Toronto Maple Leafs' },
        'logo' => 'https://assets.nhle.com/logos/nhl/svg/TOR_light.svg'
      },
      'bottomSeedTeam' => {
        'id' => 9,
        'abbrev' => 'OTT',
        'name' => { 'default' => 'Ottawa Senators' },
        'logo' => 'https://assets.nhle.com/logos/nhl/svg/OTT_light.svg'
      }
    }
  ]
}
puts "Valid bracket format: #{validator.validate_playoffs_response(bracket_response)}"

# Test playoff series format
puts "\n2. Testing playoff-series format"
series_response = {
  'round' => 1,
  'seriesLetter' => 'A',
  'neededToWin' => 4,
  'topSeedTeam' => {
    'id' => 10,
    'abbrev' => 'TOR',
    'seriesWins' => 1,
    'name' => { 'default' => 'Maple Leafs' }
  },
  'bottomSeedTeam' => {
    'id' => 9,
    'abbrev' => 'OTT',
    'seriesWins' => 0,
    'name' => { 'default' => 'Senators' }
  },
  'games' => [
    {
      'id' => 2_024_030_111,
      'gameType' => 3,
      'gameNumber' => 1,
      'startTimeUTC' => '2025-04-20T23:00:00Z',
      'gameState' => 'OFF',
      'awayTeam' => {
        'id' => 9,
        'abbrev' => 'OTT',
        'score' => 2
      },
      'homeTeam' => {
        'id' => 10,
        'abbrev' => 'TOR',
        'score' => 6
      }
    }
  ]
}
puts "Valid series format: #{validator.validate_playoffs_response(series_response)}"

# Test playoff rounds format
puts "\n3. Testing playoffRounds format"
rounds_response = {
  'currentRound' => 1,
  'playoffRounds' => [
    {
      'round' => 1,
      'series' => [
        {
          'seriesCode' => 'A',
          'seriesStatus' => 'In Progress',
          'matchupTeams' => [
            {
              'teamAbbrev' => 'TOR',
              'teamName' => { 'default' => 'Maple Leafs' },
              'seriesWins' => 1
            },
            {
              'teamAbbrev' => 'OTT',
              'teamName' => { 'default' => 'Senators' },
              'seriesWins' => 0
            }
          ],
          'games' => [
            {
              'gameDate' => '2025-04-20',
              'gameNumber' => 1,
              'gameState' => 'OFF',
              'awayTeam' => { 'abbrev' => 'OTT' },
              'homeTeam' => { 'abbrev' => 'TOR' }
            }
          ]
        }
      ]
    }
  ],
  'season' => '20242025'
}
puts "Valid playoffRounds format: #{validator.validate_playoffs_response(rounds_response)}"

# Test carousel format
puts "\n4. Testing playoff-series carousel format"
carousel_response = {
  'seasonId' => 20_242_025,
  'currentRound' => 1,
  'rounds' => [
    {
      'roundNumber' => 1,
      'roundLabel' => '1st-round',
      'roundAbbrev' => 'R1',
      'series' => [
        {
          'seriesLetter' => 'A',
          'roundNumber' => 1,
          'seriesLabel' => '1st-round',
          'seriesLink' => '/schedule/playoff-series/2025/series-a/senators-vs-mapleleafs',
          'bottomSeed' => {
            'id' => 9,
            'abbrev' => 'OTT',
            'wins' => 0,
            'logo' => 'https://assets.nhle.com/logos/nhl/svg/OTT_light.svg'
          },
          'topSeed' => {
            'id' => 10,
            'abbrev' => 'TOR',
            'wins' => 1,
            'logo' => 'https://assets.nhle.com/logos/nhl/svg/TOR_light.svg'
          },
          'neededToWin' => 4
        }
      ]
    }
  ]
}
puts "Valid carousel format: #{validator.validate_playoffs_response(carousel_response)}"

# Test legacy format
puts "\n5. Testing legacy playoff format"
legacy_response = {
  'id' => 1,
  'name' => 'Playoffs',
  'season' => '20242025',
  'defaultRound' => 1,
  'rounds' => []
}
puts "Valid legacy format: #{validator.validate_playoffs_response(legacy_response)}"

puts "\n===== Test validation complete ====="
