require 'spec_helper'
require 'json'
require 'date'
require_relative '../lib/playoff_processor'

RSpec.describe PlayoffProcessor do
  let(:processor) { PlayoffProcessor.new('spec/fixtures') }
  
  let(:sample_playoffs_standings_response) do
    {
      'rounds' => [
        {
          'roundNumber' => 1,
          'names' => { 'name' => 'First Round' },
          'series' => [
            {
              'seriesCode' => 'A1',
              'seriesStatus' => 'In Progress',
              'matchupTeams' => [
                {
                  'teamName' => { 'default' => 'Boston Bruins' },
                  'teamAbbrev' => { 'default' => 'BOS' },
                  'teamLogo' => 'logo.png',
                  'homeRoad' => 'H',
                  'seed' => 1,
                  'wins' => 50,
                  'losses' => 20,
                  'otLosses' => 12,
                  'seriesWins' => 2
                },
                {
                  'teamName' => { 'default' => 'Toronto Maple Leafs' },
                  'teamAbbrev' => { 'default' => 'TOR' },
                  'teamLogo' => 'logo2.png',
                  'homeRoad' => 'R',
                  'seed' => 8,
                  'wins' => 45,
                  'losses' => 25,
                  'otLosses' => 12,
                  'seriesWins' => 1
                }
              ],
              'games' => [
                {
                  'gameNumber' => 1,
                  'gameState' => 'Final',
                  'startTimeUTC' => '2025-04-10T23:00:00Z',
                  'homeTeam' => { 'score' => 3 },
                  'awayTeam' => { 'score' => 2 }
                }
              ]
            }
          ]
        }
      ]
    }
  end

  let(:sample_playoffs_now_response) do
    {
      'currentRound' => 1,
      'playoffRounds' => [
        {
          'round' => 1,
          'names' => { 'name' => 'First Round' },
          'series' => [
            {
              'seriesCode' => 'A1',
              'seriesStatus' => 'In Progress',
              'matchupTeams' => [
                {
                  'teamName' => { 'default' => 'Boston Bruins' },
                  'teamAbbrev' => { 'default' => 'BOS' },
                  'logo' => 'logo.png',
                  'homeIndicator' => true,
                  'seed' => 1,
                  'wins' => 50,
                  'losses' => 20,
                  'otLosses' => 12,
                  'seriesWins' => 2
                },
                {
                  'teamName' => { 'default' => 'Toronto Maple Leafs' },
                  'teamAbbrev' => { 'default' => 'TOR' },
                  'logo' => 'logo2.png',
                  'homeIndicator' => false,
                  'seed' => 8,
                  'wins' => 45,
                  'losses' => 25,
                  'otLosses' => 12,
                  'seriesWins' => 1
                }
              ],
              'games' => [
                {
                  'seriesGameNumber' => 1,
                  'gameStatus' => 'Final',
                  'startTimeUTC' => '2025-04-10T23:00:00Z',
                  'homeTeam' => { 'score' => 3 },
                  'awayTeam' => { 'score' => 2 }
                }
              ]
            }
          ]
        }
      ]
    }
  end

  describe '#initialize' do
    it 'initializes with default fallback path' do
      processor = PlayoffProcessor.new
      expect(processor.instance_variable_get(:@fallback_path)).to eq('spec/fixtures')
    end

    it 'initializes with custom fallback path' do
      processor = PlayoffProcessor.new('custom/path')
      expect(processor.instance_variable_get(:@fallback_path)).to eq('custom/path')
    end

    it 'initializes with empty data structures' do
      expect(processor.playoff_data).to eq({})
      expect(processor.playoff_rounds).to eq([])
      expect(processor.cup_odds).to eq({})
      expect(processor.fan_cup_odds).to eq({})
      expect(processor.is_playoff_time).to be false
    end
  end

  describe '#is_near_playoff_time?' do
    it 'returns true for April' do
      allow(Date).to receive(:today).and_return(Date.new(2025, 4, 15))
      expect(processor.is_near_playoff_time?).to be true
    end

    it 'returns true for May' do
      allow(Date).to receive(:today).and_return(Date.new(2025, 5, 15))
      expect(processor.is_near_playoff_time?).to be true
    end

    it 'returns true for June' do
      allow(Date).to receive(:today).and_return(Date.new(2025, 6, 15))
      expect(processor.is_near_playoff_time?).to be true
    end

    it 'returns false for other months' do
      [1, 2, 3, 7, 8, 9, 10, 11, 12].each do |month|
        allow(Date).to receive(:today).and_return(Date.new(2025, month, 15))
        expect(processor.is_near_playoff_time?).to be false
      end
    end
  end

  describe '#fetch_playoff_data' do
    before do
      # Mock HTTParty to avoid actual API calls
      allow(HTTParty).to receive(:get).and_return(double(code: 404, body: '{}'))
      # Mock validator to control validation
      allow(processor.instance_variable_get(:@validator)).to receive(:validate_playoffs_response).and_return(false)
      allow(processor.instance_variable_get(:@validator)).to receive(:handle_api_failure).and_return({})
    end

    it 'tries playoffs/now endpoint first' do
      expect(HTTParty).to receive(:get).with("https://api-web.nhle.com/v1/playoffs/now")
      processor.fetch_playoff_data
    end

    it 'falls back to standings/playoffs endpoint if first fails' do
      expect(HTTParty).to receive(:get).with("https://api-web.nhle.com/v1/playoffs/now")
      expect(HTTParty).to receive(:get).with("https://api-web.nhle.com/v1/standings/playoffs")
      processor.fetch_playoff_data
    end

    it 'sets is_playoff_time based on date when APIs fail' do
      allow(processor).to receive(:is_near_playoff_time?).and_return(true)
      processor.fetch_playoff_data
      expect(processor.is_playoff_time).to be true
    end

    it 'returns false when all data sources fail' do
      result = processor.fetch_playoff_data
      expect(result).to be false
    end
  end

  describe '#process_playoff_data' do
    before do
      processor.instance_variable_set(:@playoff_data, sample_playoffs_standings_response)
    end

    it 'processes playoff data into structured rounds' do
      processor.process_playoff_data
      rounds = processor.playoff_rounds

      expect(rounds.length).to eq(1)
      expect(rounds.first[:name]).to eq('First Round')
      expect(rounds.first[:series].length).to eq(1)
    end

    it 'formats series data correctly' do
      processor.process_playoff_data
      series = processor.playoff_rounds.first[:series].first

      expect(series[:id]).to eq('A1')
      expect(series[:status]).to eq('In Progress')
      expect(series[:home_wins]).to eq(2)
      expect(series[:away_wins]).to eq(1)
    end

    it 'handles empty rounds data' do
      processor.instance_variable_set(:@playoff_data, { 'rounds' => [] })
      processor.process_playoff_data
      expect(processor.playoff_rounds).to eq([])
    end

    it 'handles missing rounds key' do
      processor.instance_variable_set(:@playoff_data, {})
      processor.process_playoff_data
      expect(processor.playoff_rounds).to eq([])
    end
  end

  describe '#process_playoff_data_new_format' do
    before do
      processor.instance_variable_set(:@playoff_data, sample_playoffs_now_response)
    end

    it 'processes new format playoff data into structured rounds' do
      processor.process_playoff_data_new_format
      rounds = processor.playoff_rounds

      expect(rounds.length).to eq(1)
      expect(rounds.first[:name]).to eq('First Round')
      expect(rounds.first[:series].length).to eq(1)
    end

    it 'handles missing round names' do
      data = sample_playoffs_now_response.dup
      data['playoffRounds'][0].delete('names')
      processor.instance_variable_set(:@playoff_data, data)

      processor.process_playoff_data_new_format
      rounds = processor.playoff_rounds

      expect(rounds.first[:name]).to eq('Round 1')
    end

    it 'handles empty playoffRounds data' do
      processor.instance_variable_set(:@playoff_data, { 'playoffRounds' => [] })
      processor.process_playoff_data_new_format
      expect(processor.playoff_rounds).to eq([])
    end

    it 'handles missing playoffRounds key' do
      processor.instance_variable_set(:@playoff_data, {})
      processor.process_playoff_data_new_format
      expect(processor.playoff_rounds).to eq([])
    end
  end

  describe '#format_playoff_team' do
    let(:sample_team) do
      {
        'teamName' => { 'default' => 'Boston Bruins' },
        'teamAbbrev' => { 'default' => 'BOS' },
        'teamLogo' => 'logo.png',
        'seed' => 1,
        'wins' => 50,
        'losses' => 20,
        'otLosses' => 12
      }
    end

    it 'formats team data correctly' do
      result = processor.format_playoff_team(sample_team)

      expect(result[:name]).to eq('Boston Bruins')
      expect(result[:abbrev]).to eq('BOS')
      expect(result[:logo]).to eq('logo.png')
      expect(result[:seed]).to eq(1)
      expect(result[:record]).to eq('50-20-12')
    end

    it 'returns TBD placeholders for nil team' do
      result = processor.format_playoff_team(nil)

      expect(result[:name]).to eq('TBD')
      expect(result[:abbrev]).to eq('TBD')
      expect(result[:seed]).to eq('TBD')
    end
  end

  describe '#format_playoff_team_new_format' do
    let(:sample_team_new) do
      {
        'teamName' => { 'default' => 'Boston Bruins' },
        'teamAbbrev' => { 'default' => 'BOS' },
        'logo' => 'logo.png',
        'seed' => 1,
        'wins' => 50,
        'losses' => 20,
        'otLosses' => 12
      }
    end

    it 'formats new format team data correctly' do
      result = processor.format_playoff_team_new_format(sample_team_new)

      expect(result[:name]).to eq('Boston Bruins')
      expect(result[:abbrev]).to eq('BOS')
      expect(result[:logo]).to eq('logo.png')
      expect(result[:seed]).to eq(1)
      expect(result[:record]).to eq('50-20-12')
    end

    it 'handles alternative field names' do
      alt_team = {
        'name' => { 'default' => 'Boston Bruins' },
        'abbrev' => { 'default' => 'BOS' },
        'teamLogo' => 'logo.png',
        'seed' => 1
      }

      result = processor.format_playoff_team_new_format(alt_team)

      expect(result[:name]).to eq('Boston Bruins')
      expect(result[:abbrev]).to eq('BOS')
      expect(result[:logo]).to eq('logo.png')
      expect(result[:record]).to eq('TBD')
    end

    it 'returns TBD placeholders for nil team' do
      result = processor.format_playoff_team_new_format(nil)

      expect(result[:name]).to eq('TBD')
      expect(result[:abbrev]).to eq('TBD')
      expect(result[:seed]).to eq('TBD')
    end
  end

  describe '#format_playoff_game' do
    let(:sample_game) do
      {
        'gameNumber' => 1,
        'gameState' => 'Final',
        'startTimeUTC' => '2025-04-10T23:00:00Z',
        'homeTeam' => { 'score' => 3 },
        'awayTeam' => { 'score' => 2 }
      }
    end

    it 'formats game data correctly' do
      result = processor.format_playoff_game(sample_game)

      expect(result[:number]).to eq(1)
      expect(result[:status]).to eq('Final')
      expect(result[:start_time]).to eq('2025-04-10T23:00:00Z')
      expect(result[:home_score]).to eq(3)
      expect(result[:away_score]).to eq(2)
    end

    it 'returns empty hash for nil game' do
      result = processor.format_playoff_game(nil)
      expect(result).to eq({})
    end
  end

  describe '#format_playoff_game_new_format' do
    let(:sample_game_new) do
      {
        'seriesGameNumber' => 1,
        'gameStatus' => 'Final',
        'startTimeUTC' => '2025-04-10T23:00:00Z',
        'homeTeam' => { 'score' => 3 },
        'awayTeam' => { 'score' => 2 }
      }
    end

    it 'formats new format game data correctly' do
      result = processor.format_playoff_game_new_format(sample_game_new)

      expect(result[:number]).to eq(1)
      expect(result[:status]).to eq('Final')
      expect(result[:start_time]).to eq('2025-04-10T23:00:00Z')
      expect(result[:home_score]).to eq(3)
      expect(result[:away_score]).to eq(2)
    end

    it 'handles alternative field names' do
      alt_game = {
        'gameNumber' => 2,
        'gameState' => 'In Progress'
      }

      result = processor.format_playoff_game_new_format(alt_game)

      expect(result[:number]).to eq(2)
      expect(result[:status]).to eq('In Progress')
      expect(result[:home_score]).to eq(0)
      expect(result[:away_score]).to eq(0)
    end

    it 'returns empty hash for nil game' do
      result = processor.format_playoff_game_new_format(nil)
      expect(result).to eq({})
    end
  end

  describe '#calculate_cup_odds' do
    before do
      processor.instance_variable_set(:@is_playoff_time, true)
      processor.instance_variable_set(:@playoff_data, sample_playoffs_standings_response)
    end

    it 'calculates odds for playoff teams' do
      processor.calculate_cup_odds
      odds = processor.cup_odds

      expect(odds).to have_key('BOS')
      expect(odds).to have_key('TOR')
      expect(odds['BOS']).to be_a(Float)
      expect(odds['TOR']).to be_a(Float)
    end

    it 'does not calculate odds when not playoff time' do
      processor.instance_variable_set(:@is_playoff_time, false)
      processor.calculate_cup_odds
      expect(processor.cup_odds).to be_empty
    end

    it 'handles empty playoff data' do
      processor.instance_variable_set(:@playoff_data, { 'rounds' => [] })
      processor.calculate_cup_odds
      expect(processor.cup_odds).to be_empty
    end
  end

  describe '#calculate_fan_cup_odds' do
    let(:manager_team_map) do
      {
        'BOS' => 'Alice',
        'TOR' => 'Bob',
        'FLA' => 'N/A'
      }
    end

    before do
      processor.instance_variable_set(:@is_playoff_time, true)
      processor.instance_variable_set(:@cup_odds, { 'BOS' => 60.0, 'TOR' => 40.0 })
    end

    it 'calculates fan odds based on team odds' do
      processor.calculate_fan_cup_odds(manager_team_map)
      fan_odds = processor.fan_cup_odds

      expect(fan_odds).to have_key('Alice')
      expect(fan_odds).to have_key('Bob')
      expect(fan_odds['Alice']).to eq(60.0)
      expect(fan_odds['Bob']).to eq(40.0)
    end

    it 'excludes teams with no fans' do
      processor.calculate_fan_cup_odds(manager_team_map)
      fan_odds = processor.fan_cup_odds

      expect(fan_odds).not_to have_key('N/A')
    end

    it 'sorts fans by odds descending' do
      processor.calculate_fan_cup_odds(manager_team_map)
      fan_odds = processor.fan_cup_odds

      odds_values = fan_odds.values
      expect(odds_values).to eq(odds_values.sort.reverse)
    end

    it 'returns empty hash when not playoff time' do
      processor.instance_variable_set(:@is_playoff_time, false)
      processor.calculate_fan_cup_odds(manager_team_map)
      expect(processor.fan_cup_odds).to be_empty
    end

    it 'returns empty hash when cup_odds is empty' do
      processor.instance_variable_set(:@cup_odds, {})
      processor.calculate_fan_cup_odds(manager_team_map)
      expect(processor.fan_cup_odds).to be_empty
    end
  end

  describe '#valid_playoff_data?' do
    it 'delegates to validator' do
      validator = processor.instance_variable_get(:@validator)
      expect(validator).to receive(:validate_playoffs_response).with({ 'test' => 'data' })
      processor.valid_playoff_data?({ 'test' => 'data' })
    end
  end
end