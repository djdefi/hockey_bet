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
      invalid_response = { 'standingss' => [] }  # typo in key name
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
      invalid_response = { 'games' => [] }  # wrong key name
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
      expect(result).to eq({'test' => 'data'})
      
      tempfile.unlink  # delete the temp file
    end
    
    it 'returns empty structure for teams when fallback file does not exist' do
      result = validator.handle_api_failure('teams', 'nonexistent_file.json')
      expect(result).to eq({'standings' => []})
    end
    
    it 'returns empty structure for schedule when fallback file does not exist' do
      result = validator.handle_api_failure('schedule', 'nonexistent_file.json')
      expect(result).to eq({'gameWeek' => []})
    end

    it 'returns empty structure for playoffs when fallback file does not exist' do
      result = validator.handle_api_failure('playoffs', 'nonexistent_file.json')
      expect(result).to eq({'rounds' => []})
    end
  end

  describe '#validate_playoffs_response' do
    it 'returns true for valid standings/playoffs response' do
      valid_response = {
        'rounds' => [
          {
            'roundNumber' => 1,
            'names' => { 'name' => 'First Round' },
            'series' => [
              {
                'matchupTeams' => [
                  {
                    'teamAbbrev' => { 'default' => 'BOS' },
                    'teamName' => { 'default' => 'Boston Bruins' }
                  }
                ]
              }
            ]
          }
        ]
      }
      
      expect(validator.validate_playoffs_response(valid_response)).to be true
    end

    it 'returns true for valid playoffs/now response' do
      valid_response = {
        'currentRound' => 1,
        'playoffRounds' => [
          {
            'round' => 1,
            'series' => [
              {
                'seriesCode' => 'A1',
                'seriesStatus' => 'In Progress',
                'matchupTeams' => [
                  {
                    'teamAbbrev' => 'BOS'
                  }
                ]
              }
            ]
          }
        ]
      }
      
      expect(validator.validate_playoffs_response(valid_response)).to be true
    end

    it 'returns true for empty rounds (off-season)' do
      valid_empty_response = { 'rounds' => [] }
      expect(validator.validate_playoffs_response(valid_empty_response)).to be true
    end

    it 'returns false for nil response' do
      expect(validator.validate_playoffs_response(nil)).to be false
    end

    it 'returns false for response with wrong structure' do
      invalid_response = { 'wrongKey' => [] }
      expect(validator.validate_playoffs_response(invalid_response)).to be false
    end

    it 'returns false for response with invalid round structure' do
      invalid_response = {
        'rounds' => [
          {
            # missing required keys
            'wrongKey' => 'value'
          }
        ]
      }
      
      expect(validator.validate_playoffs_response(invalid_response)).to be false
    end
  end
end
