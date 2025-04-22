require 'spec_helper'
require 'tempfile'
require_relative '../lib/api_validator'

RSpec.describe ApiValidator do
  let(:logger) { instance_double(Logger, error: nil, debug: nil) }
  let(:validator) { ApiValidator.new(logger) }

  describe '#validate_teams_response' do
    it 'returns true for valid response' do
      valid_response = {
        'standings' => [
          {
            'teamName' => { 'default' => 'Boston Bruins' },
            'teamAbbrev' => { 'default' => 'BOS' },
            'wins' => 50,
            'losses' => 15,
            'points' => 106,
            'divisionSequence' => 1,
            'wildcardSequence' => 0
          }
        ]
      }

      expect(validator.validate_teams_response(valid_response)).to be true
    end

    it 'returns false for nil response' do
      expect(validator.validate_teams_response(nil)).to be false
    end

    it 'returns false for response with wrong structure' do
      invalid_response = { 'standingss' => [] } # typo in key name
      expect(validator.validate_teams_response(invalid_response)).to be false
    end

    it 'returns false for response with missing required keys' do
      invalid_response = {
        'standings' => [
          {
            'teamName' => { 'default' => 'Boston Bruins' },
            # missing teamAbbrev
            'wins' => 50,
            'losses' => 15,
            'points' => 106
            # missing divisionSequence and wildcardSequence
          }
        ]
      }

      expect(validator.validate_teams_response(invalid_response)).to be false
    end
  end

  describe '#validate_schedule_response' do
    it 'returns true for valid response' do
      valid_response = {
        'gameWeek' => [
          {
            'date' => '2025-04-10',
            'games' => [
              {
                'startTimeUTC' => '2025-04-10T23:00:00Z',
                'awayTeam' => {
                  'abbrev' => 'TOR',
                  'placeName' => { 'default' => 'Toronto' }
                },
                'homeTeam' => {
                  'abbrev' => 'BOS',
                  'placeName' => { 'default' => 'Boston' }
                }
              }
            ]
          }
        ]
      }

      expect(validator.validate_schedule_response(valid_response)).to be true
    end

    it 'returns true for empty game week (off-season)' do
      valid_empty_response = { 'gameWeek' => [] }
      expect(validator.validate_schedule_response(valid_empty_response)).to be true
    end

    it 'returns false for nil response' do
      expect(validator.validate_schedule_response(nil)).to be false
    end

    it 'returns false for response with wrong structure' do
      invalid_response = { 'games' => [] } # wrong key name
      expect(validator.validate_schedule_response(invalid_response)).to be false
    end
  end

  describe '#handle_api_failure' do
    it 'returns fallback data when file exists' do
      # Create temporary fallback file
      tempfile = Tempfile.new(['fallback', '.json'])
      tempfile.write('{"test": "data"}')
      tempfile.close

      result = validator.handle_api_failure('test', tempfile.path)
      expect(result).to eq({ 'test' => 'data' })

      tempfile.unlink # delete the temp file
    end

    it 'returns empty structure for teams when fallback file does not exist' do
      result = validator.handle_api_failure('teams', 'nonexistent_file.json')
      expect(result).to eq({ 'standings' => [] })
    end

    it 'returns empty structure for schedule when fallback file does not exist' do
      result = validator.handle_api_failure('schedule', 'nonexistent_file.json')
      expect(result).to eq({ 'gameWeek' => [] })
    end
  end

  describe '#validate_playoffs_response' do
    context 'with playoff-bracket format' do
      it 'returns true for valid playoff bracket response' do
        valid_response = {
          'rounds' => [
            {
              'roundNumber' => 1,
              'names' => { 'name' => '1st Round' },
              'series' => [
                {
                  'matchupTeams' => [
                    {
                      'homeRoad' => 'H',
                      'teamAbbrev' => { 'default' => 'TOR' },
                      'teamName' => { 'default' => 'Toronto Maple Leafs' },
                      'seed' => 1,
                      'seriesWins' => 1
                    },
                    {
                      'homeRoad' => 'R',
                      'teamAbbrev' => { 'default' => 'OTT' },
                      'teamName' => { 'default' => 'Ottawa Senators' },
                      'seed' => 4,
                      'seriesWins' => 0
                    }
                  ],
                  'games' => [
                    {
                      'gameDate' => '2025-04-20',
                      'gameNumber' => 1,
                      'gameState' => 'FINAL'
                    }
                  ]
                }
              ]
            }
          ]
        }

        expect(validator.validate_playoffs_response(valid_response)).to be true
      end

      it 'returns false for nil response' do
        expect(validator.validate_playoffs_response(nil)).to be false
      end

      it 'returns false for bracket response with missing required fields' do
        invalid_response = {
          'bracketLogo' => 'https://assets.nhle.com/logos/playoffs/png/scp-20242025-horizontal-banner-en.png',
          'series' => [
            {
              'seriesLetter' => 'A',
              'playoffRound' => 1,
              # Missing topSeedWins and bottomSeedWins
              'topSeedTeam' => {
                'id' => 10,
                'abbrev' => 'TOR'
                # Missing name and logo
              }
            }
          ]
        }

        expect(validator.validate_playoffs_response(invalid_response)).to be false
      end
    end

    context 'with playoff-series format' do
      it 'returns true for valid playoff series response' do
        valid_response = {
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
                      'seriesWins' => 1,
                      'homeIndicator' => true
                    },
                    {
                      'teamAbbrev' => 'OTT',
                      'teamName' => { 'default' => 'Senators' },
                      'seriesWins' => 0,
                      'homeIndicator' => false
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

        expect(validator.validate_playoffs_response(valid_response)).to be true
      end

      it 'returns false for series response with missing required fields' do
        invalid_response = {
          'round' => 1,
          'seriesLetter' => 'A',
          # Missing neededToWin
          'topSeedTeam' => {
            'id' => 10
            # Missing other required fields
          }
          # Missing games array
        }

        expect(validator.validate_playoffs_response(invalid_response)).to be false
      end
    end

    context 'with playoffRounds format' do
      it 'returns true for valid playoffRounds response' do
        valid_response = {
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

        expect(validator.validate_playoffs_response(valid_response)).to be true
      end
    end

    context 'with playoff-series carousel format' do
      it 'returns true for valid carousel response' do
        valid_response = {
          'id' => 1,
          'name' => 'Playoffs',
          'season' => '20242025',
          'defaultRound' => 1,
          'rounds' => [
            {
              'roundNumber' => 1,
              'names' => { 'name' => '1st Round' },
              'series' => [
                {
                  'seriesCode' => 'A',
                  'matchupTeams' => [
                    {
                      'homeRoad' => 'H',
                      'teamAbbrev' => { 'default' => 'TOR' },
                      'teamName' => { 'default' => 'Toronto Maple Leafs' },
                      'seed' => 1,
                      'seriesWins' => 1
                    },
                    {
                      'homeRoad' => 'R',
                      'teamAbbrev' => { 'default' => 'OTT' },
                      'teamName' => { 'default' => 'Ottawa Senators' },
                      'seed' => 4,
                      'seriesWins' => 0
                    }
                  ]
                }
              ]
            }
          ]
        }

        expect(validator.validate_playoffs_response(valid_response)).to be true
      end

      it 'returns false for carousel response with missing required fields' do
        invalid_response = {
          'seasonId' => 20_242_025,
          'currentRound' => 1,
          'rounds' => [
            {
              'roundNumber' => 1,
              'series' => [
                {
                  'seriesLetter' => 'A',
                  # Missing neededToWin and team information
                  'bottomSeed' => {
                    'id' => 9
                    # Missing wins and abbrev
                  }
                  # Missing topSeed entirely
                }
              ]
            }
          ]
        }

        expect(validator.validate_playoffs_response(invalid_response)).to be false
      end
    end

    it 'returns false for empty response' do
      expect(validator.validate_playoffs_response({})).to be false
    end

    it 'returns true for legacy format (if recognized)' do
      legacy_response = {
        'id' => 1,
        'name' => 'Playoffs',
        'season' => '20242025',
        'defaultRound' => 1,
        'rounds' => []
      }

      expect(validator.validate_playoffs_response(legacy_response)).to be true
    end
  end
end
