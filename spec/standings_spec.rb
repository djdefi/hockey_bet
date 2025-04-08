require 'spec_helper'
require 'tzinfo'
require 'time'
require 'json'
require 'erb'

# Load the refactored script
require_relative '../lib/standings_processor'

RSpec.describe 'NHL Standings Table' do
  before do
    # Load test fixtures
    teams_json = File.read('spec/fixtures/teams.json')
    schedule_json = File.read('spec/fixtures/schedule.json')
    
    @teams = JSON.parse(teams_json)['standings']
    @schedule = JSON.parse(schedule_json)['gameWeek']
    @next_games = find_next_games(@teams, @schedule)
    @manager_team_map = {
      'BOS' => 'Alice',
      'TOR' => 'Bob',
      'FLA' => 'Charlie',
      'TBL' => 'Dave',
      'DET' => 'N/A',
      'BUF' => 'N/A',
      'OTT' => 'N/A',
      'MTL' => 'N/A'
    }
  end

  describe '#playoff_status_for' do
    it 'returns :clinched for teams with divisionSequence <= 3' do
      # Boston, Florida, and Toronto have divisionSequence 1, 2, and 3
      expect(playoff_status_for(@teams[0])).to eq(:clinched) # Boston
      expect(playoff_status_for(@teams[1])).to eq(:clinched) # Florida
      expect(playoff_status_for(@teams[2])).to eq(:clinched) # Toronto
    end

    it 'returns :contending for teams with wildcardSequence <= 2' do
      # Tampa Bay has wildcardSequence 1
      expect(playoff_status_for(@teams[3])).to eq(:contending) # Tampa Bay
    end

    it 'returns :eliminated for teams with wildcardSequence > 2' do
      # Detroit, Buffalo, Ottawa, and Montreal have wildcardSequence > 2
      expect(playoff_status_for(@teams[4])).to eq(:eliminated) # Detroit
      expect(playoff_status_for(@teams[5])).to eq(:eliminated) # Buffalo
      expect(playoff_status_for(@teams[6])).to eq(:eliminated) # Ottawa
      expect(playoff_status_for(@teams[7])).to eq(:eliminated) # Montreal
    end
  end

  describe '#convert_utc_to_pacific' do
    it 'correctly converts UTC to Pacific time' do
      # April 9, 2025 at 23:00 UTC should be April 9, 2025 at 16:00 Pacific (DST)
      utc_time = '2025-04-09T23:00:00Z'
      pacific_time = convert_utc_to_pacific(utc_time)
      
      expect(pacific_time.hour).to eq(16)
      expect(pacific_time.min).to eq(0)
      expect(pacific_time.day).to eq(9)
      expect(pacific_time.month).to eq(4)
      expect(pacific_time.year).to eq(2025)
    end

    it 'returns TBD when input is TBD' do
      expect(convert_utc_to_pacific('TBD')).to eq('TBD')
    end
  end

  describe '#format_game_time' do
    it 'formats the time correctly' do
      time = Time.new(2025, 4, 9, 16, 30)
      expect(format_game_time(time)).to eq('4/9 16:30')
    end

    it 'returns TBD when input is TBD' do
      expect(format_game_time('TBD')).to eq('TBD')
    end
  end

  describe '#check_fan_team_opponent' do
    it 'marks games between two fan teams correctly' do
      # Set up a scenario where Boston plays Toronto
      next_games = {
        'BOS' => {
          'awayTeam' => {'abbrev' => 'TOR'},
          'homeTeam' => {'abbrev' => 'BOS'}
        },
        'TOR' => {
          'awayTeam' => {'abbrev' => 'TOR'},
          'homeTeam' => {'abbrev' => 'BOS'}
        }
      }
      
      check_fan_team_opponent(next_games, @manager_team_map)
      
      # Both Boston and Toronto have fans, so both should be marked
      expect(next_games['BOS']['isFanTeamOpponent']).to be(true)
      expect(next_games['TOR']['isFanTeamOpponent']).to be(true)
    end

    it 'does not mark games where one team has no fan' do
      # Set up a scenario where Boston plays Detroit
      next_games = {
        'BOS' => {
          'awayTeam' => {'abbrev' => 'DET'},
          'homeTeam' => {'abbrev' => 'BOS'}
        },
        'DET' => {
          'awayTeam' => {'abbrev' => 'DET'},
          'homeTeam' => {'abbrev' => 'BOS'}
        }
      }
      
      check_fan_team_opponent(next_games, @manager_team_map)
      
      # Detroit has no fan, so neither should be marked
      expect(next_games['BOS']['isFanTeamOpponent']).to be(false)
      expect(next_games['DET']['isFanTeamOpponent']).to be(false)
    end
  end

  describe '#get_opponent_name' do
    it 'returns the correct opponent name for a home team' do
      game = {
        'awayTeam' => {'abbrev' => 'TOR', 'placeName' => {'default' => 'Toronto'}},
        'homeTeam' => {'abbrev' => 'BOS', 'placeName' => {'default' => 'Boston'}}
      }
      
      expect(get_opponent_name(game, 'BOS')).to eq('Toronto')
    end

    it 'returns the correct opponent name for an away team' do
      game = {
        'awayTeam' => {'abbrev' => 'TOR', 'placeName' => {'default' => 'Toronto'}},
        'homeTeam' => {'abbrev' => 'BOS', 'placeName' => {'default' => 'Boston'}}
      }
      
      expect(get_opponent_name(game, 'TOR')).to eq('Boston')
    end

    it 'returns TBD when the game is nil' do
      expect(get_opponent_name(nil, 'BOS')).to eq('TBD')
    end
  end

  describe 'PLAYOFF_STATUS constant' do
    it 'has the correct structure with expected keys' do
      expect(PLAYOFF_STATUS).to have_key(:clinched)
      expect(PLAYOFF_STATUS).to have_key(:contending)
      expect(PLAYOFF_STATUS).to have_key(:eliminated)
      
      expect(PLAYOFF_STATUS[:clinched]).to include(:class, :icon, :label, :aria_label)
      expect(PLAYOFF_STATUS[:contending]).to include(:class, :icon, :label, :aria_label)
      expect(PLAYOFF_STATUS[:eliminated]).to include(:class, :icon, :label, :aria_label)
    end
  end
end
