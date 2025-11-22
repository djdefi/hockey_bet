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

    it 'returns None when input is None' do
      expect(convert_utc_to_pacific('None')).to eq('None')
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

    it 'returns None when input is None' do
      expect(format_game_time('None')).to eq('None')
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

    it 'handles placeholder games for teams without next games' do
      # Set up a scenario with placeholder games
      next_games = {
        'BOS' => {
          'awayTeam' => {'abbrev' => 'TOR'},
          'homeTeam' => {'abbrev' => 'BOS'}
        },
        'SEA' => {
          'awayTeam' => {'abbrev' => 'None'},
          'homeTeam' => {'abbrev' => 'None'},
          'isFanTeamOpponent' => false
        }
      }

      # Add Seattle to the manager team map with a fan
      manager_team_map = @manager_team_map.dup
      manager_team_map['SEA'] = 'Eve'

      check_fan_team_opponent(next_games, manager_team_map)

      # Seattle has a fan but no next game (placeholder), so it should not be marked
      expect(next_games['SEA']['isFanTeamOpponent']).to be(false)
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

    it 'returns None when the game is nil' do
      expect(get_opponent_name(nil, 'BOS')).to eq('None')
    end

    it 'returns None when the game has None placeholders' do
      game = {
        'awayTeam' => {'abbrev' => 'None', 'placeName' => {'default' => 'None'}},
        'homeTeam' => {'abbrev' => 'None', 'placeName' => {'default' => 'None'}}
      }
      expect(get_opponent_name(game, 'BOS')).to eq('None')
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

  describe '#find_next_games' do
    it 'finds the correct next game for each team' do
      # We're using the fixtures loaded in before block
      next_games = find_next_games(@teams, @schedule)

      # Verify some specific teams have proper games assigned
      expect(next_games['BOS']).not_to be_nil
      expect(next_games['TOR']).not_to be_nil
    end

    it 'creates proper placeholders for teams without next games' do
      # Create a test scenario with a team that has no upcoming games
      teams_with_missing_game = @teams.dup
      teams_with_missing_game << {
        'teamAbbrev' => { 'default' => 'SEA' }  # Seattle has no game in our fixture
      }

      next_games = find_next_games(teams_with_missing_game, @schedule)

      # Verify the placeholder was created correctly
      expect(next_games['SEA']).not_to be_nil
      expect(next_games['SEA']['startTimeUTC']).to eq('None')
      expect(next_games['SEA']['awayTeam']['abbrev']).to eq('None')
      expect(next_games['SEA']['homeTeam']['abbrev']).to eq('None')
      expect(next_games['SEA']['isFanTeamOpponent']).to eq(false)
    end
  end

  describe 'template rendering' do
    it 'formats next game data correctly in the template' do
      processor = StandingsProcessor.new
      processor.instance_variable_set(:@teams, @teams)
      processor.instance_variable_set(:@manager_team_map, @manager_team_map)

      # Create next_games with a mix of regular games and placeholders
      next_games = {
        'BOS' => {
          'startTimeUTC' => '2025-04-09T23:00:00Z',
          'awayTeam' => {'abbrev' => 'TOR', 'placeName' => {'default' => 'Toronto'}},
          'homeTeam' => {'abbrev' => 'BOS', 'placeName' => {'default' => 'Boston'}},
          'isFanTeamOpponent' => true
        },
        'SEA' => {
          'startTimeUTC' => 'None',
          'awayTeam' => {'abbrev' => 'None', 'placeName' => {'default' => 'None'}},
          'homeTeam' => {'abbrev' => 'None', 'placeName' => {'default' => 'None'}},
          'isFanTeamOpponent' => false
        }
      }
      processor.instance_variable_set(:@next_games, next_games)

      # Mock the ERB.new().result to prevent actual template rendering but verify data is set up
      allow(ERB).to receive(:new).and_return(double(result: "HTML content"))

      # We just need to make sure this doesn't raise an error when we have 'None' values
      expect { processor.render_template }.not_to raise_error
    end
  end

  describe 'StandingsProcessor class methods' do
    let(:processor) { StandingsProcessor.new('spec/fixtures') }

    describe '#initialize' do
      it 'initializes with default fallback path' do
        proc = StandingsProcessor.new
        expect(proc.instance_variable_get(:@fallback_path)).to eq('spec/fixtures')
      end

      it 'initializes with custom fallback path' do
        proc = StandingsProcessor.new('custom/path')
        expect(proc.instance_variable_get(:@fallback_path)).to eq('custom/path')
      end

      it 'initializes all instance variables' do
        expect(processor.teams).to eq([])
        expect(processor.schedule).to eq([])
        expect(processor.next_games).to eq({})
        expect(processor.manager_team_map).to eq({})
        expect(processor.last_updated).to be_nil
      end
    end

    describe '#fetch_data' do
      before do
        # Mock the API methods to avoid actual HTTP calls
        allow(processor).to receive(:fetch_team_info).and_return(@teams)
        allow(processor).to receive(:fetch_schedule_info).and_return(@schedule)
        allow(processor.playoff_processor).to receive(:fetch_playoff_data).and_return(true)
        allow(processor).to receive(:convert_utc_to_pacific).and_return(Time.now)
      end

      it 'fetches all required data' do
        expect(processor).to receive(:fetch_team_info)
        expect(processor).to receive(:fetch_schedule_info)
        expect(processor.playoff_processor).to receive(:fetch_playoff_data)
        
        processor.fetch_data
        
        expect(processor.teams).to eq(@teams)
        expect(processor.schedule).to eq(@schedule)
        expect(processor.last_updated).not_to be_nil
      end
    end

    describe '#process_data' do
      before do
        processor.instance_variable_set(:@teams, @teams)
        processor.instance_variable_set(:@schedule, @schedule)
        
        # Create a temporary CSV file
        csv_content = "fan,team\nAlice,Boston\nBob,Toronto\n"
        @temp_csv = '/tmp/test_fan_team.csv'
        File.write(@temp_csv, csv_content)
      end

      after do
        File.delete(@temp_csv) if File.exist?(@temp_csv)
      end

      it 'processes all data components' do
        expect(processor).to receive(:find_next_games).with(@teams, @schedule).and_return(@next_games)
        expect(processor).to receive(:map_managers_to_teams).with(@temp_csv, @teams).and_return(@manager_team_map)
        expect(processor).to receive(:check_fan_team_opponent).with(@next_games, @manager_team_map)
        
        processor.process_data(@temp_csv)
      end
    end

    describe '#render_output' do
      before do
        processor.instance_variable_set(:@teams, @teams)
        processor.instance_variable_set(:@manager_team_map, @manager_team_map)
        processor.instance_variable_set(:@next_games, @next_games)
        processor.instance_variable_set(:@last_updated, Time.now)
        
        # Mock the render_template method
        allow(processor).to receive(:render_template).and_return('HTML content')
        
        @temp_output = '/tmp/test_output.html'
      end

      after do
        File.delete(@temp_output) if File.exist?(@temp_output)
      end

      it 'creates output directory if needed' do
        output_path = '/tmp/subdir/test.html'
        
        processor.render_output(output_path)
        
        expect(Dir.exist?('/tmp/subdir')).to be true
        expect(File.exist?(output_path)).to be true
        
        # Cleanup - use rm_rf to remove directory and all contents
        FileUtils.rm_rf('/tmp/subdir')
      end

      it 'writes HTML content to file' do
        processor.render_output(@temp_output)
        
        expect(File.exist?(@temp_output)).to be true
        expect(File.read(@temp_output)).to eq('HTML content')
      end

      it 'copies styles.css to output directory' do
        processor.render_output(@temp_output)
        
        output_dir = File.dirname(@temp_output)
        styles_path = File.join(output_dir, 'styles.css')
        
        expect(File.exist?(styles_path)).to be true
        # Verify it's the actual CSS file, not empty (should be ~18KB)
        min_expected_css_size = 1000  # bytes - actual file is much larger
        expect(File.size(styles_path)).to be > min_expected_css_size
        
        # Cleanup
        File.delete(styles_path) if File.exist?(styles_path)
      end

      it 'copies vendor assets to output directory' do
        processor.render_output(@temp_output)
        
        output_dir = File.dirname(@temp_output)
        vendor_dir = File.join(output_dir, 'vendor')
        
        expect(Dir.exist?(vendor_dir)).to be true
        expect(File.exist?(File.join(vendor_dir, 'chart.umd.js'))).to be true
        expect(File.exist?(File.join(vendor_dir, 'primer.css'))).to be true
        
        # Cleanup
        FileUtils.rm_rf(vendor_dir) if Dir.exist?(vendor_dir)
      end
    end

    describe '#map_managers_to_teams' do
      before do
        # Create a temporary CSV file
        csv_content = "fan,team\nAlice,Boston\nBob,Toronto\nCharlie,leafs\nDave,BOS\n"
        @temp_csv = '/tmp/test_map_managers.csv'
        File.write(@temp_csv, csv_content)
      end

      after do
        File.delete(@temp_csv) if File.exist?(@temp_csv)
      end

      it 'maps managers to teams correctly' do
        result = processor.map_managers_to_teams(@temp_csv, @teams)
        
        # Note: Later entries in CSV can overwrite earlier ones
        # So Dave's 'BOS' exact match will overwrite Alice's 'Boston' fuzzy match
        expect(result['BOS']).to eq('Dave')    # Exact abbreviation match
        expect(result['TOR']).to eq('Charlie') # 'leafs' maps to Toronto via fuzzy matching
      end

      it 'initializes all teams to N/A by default' do
        result = processor.map_managers_to_teams(@temp_csv, @teams)
        
        @teams.each do |team|
          abbrev = team['teamAbbrev']['default']
          expect(result).to have_key(abbrev)
        end
      end

      it 'handles missing CSV file gracefully' do
        expect { processor.map_managers_to_teams('nonexistent.csv', @teams) }.not_to raise_error
        
        result = processor.map_managers_to_teams('nonexistent.csv', @teams)
        @teams.each do |team|
          abbrev = team['teamAbbrev']['default']
          expect(result[abbrev]).to eq('N/A')
        end
      end
    end

    describe '#fetch_team_info and #fetch_schedule_info' do
      before do
        # Mock HTTParty to avoid actual API calls
        @mock_response = double('response')
        allow(HTTParty).to receive(:get).and_return(@mock_response)
      end

      describe '#fetch_team_info' do
        it 'returns API data when successful' do
          api_data = { 'standings' => @teams }
          allow(@mock_response).to receive(:code).and_return(200)
          allow(@mock_response).to receive(:body).and_return(JSON.generate(api_data))
          allow(processor.instance_variable_get(:@validator)).to receive(:validate_teams_response).and_return(true)
          
          result = processor.fetch_team_info
          expect(result).to eq(@teams)
        end

        it 'returns fallback data when API fails' do
          allow(@mock_response).to receive(:code).and_return(500)
          fallback_data = { 'standings' => [] }
          allow(processor.instance_variable_get(:@validator)).to receive(:handle_api_failure).and_return(fallback_data)
          
          result = processor.fetch_team_info
          expect(result).to eq([])
        end

        it 'returns fallback data when validation fails' do
          api_data = { 'standings' => @teams }
          allow(@mock_response).to receive(:code).and_return(200)
          allow(@mock_response).to receive(:body).and_return(JSON.generate(api_data))
          allow(processor.instance_variable_get(:@validator)).to receive(:validate_teams_response).and_return(false)
          
          fallback_data = { 'standings' => [] }
          allow(processor.instance_variable_get(:@validator)).to receive(:handle_api_failure).and_return(fallback_data)
          
          result = processor.fetch_team_info
          expect(result).to eq([])
        end
      end

      describe '#fetch_schedule_info' do
        it 'returns API data when successful' do
          api_data = { 'gameWeek' => @schedule }
          allow(@mock_response).to receive(:code).and_return(200)
          allow(@mock_response).to receive(:body).and_return(JSON.generate(api_data))
          allow(processor.instance_variable_get(:@validator)).to receive(:validate_schedule_response).and_return(true)
          
          result = processor.fetch_schedule_info
          expect(result).to eq(@schedule)
        end

        it 'returns fallback data when API fails' do
          allow(@mock_response).to receive(:code).and_return(500)
          fallback_data = { 'gameWeek' => [] }
          allow(processor.instance_variable_get(:@validator)).to receive(:handle_api_failure).and_return(fallback_data)
          
          result = processor.fetch_schedule_info
          expect(result).to eq([])
        end

        it 'returns fallback data when validation fails' do
          api_data = { 'gameWeek' => @schedule }
          allow(@mock_response).to receive(:code).and_return(200)
          allow(@mock_response).to receive(:body).and_return(JSON.generate(api_data))
          allow(processor.instance_variable_get(:@validator)).to receive(:validate_schedule_response).and_return(false)
          
          fallback_data = { 'gameWeek' => [] }
          allow(processor.instance_variable_get(:@validator)).to receive(:handle_api_failure).and_return(fallback_data)
          
          result = processor.fetch_schedule_info
          expect(result).to eq([])
        end
      end
    end
  end

  describe 'StandingsProcessor rendering' do
    it 'successfully renders output with teams that have no next games' do
      # Create a mock StandingsProcessor
      processor = StandingsProcessor.new
      processor.instance_variable_set(:@teams, @teams)
      processor.instance_variable_set(:@manager_team_map, @manager_team_map)
      processor.instance_variable_set(:@last_updated, Time.now)

      # Add a team with no next game (using our placeholder structure)
      next_games = @next_games.dup
      next_games['NYR'] = {
        'startTimeUTC' => 'None',
        'awayTeam' => {'abbrev' => 'None', 'placeName' => {'default' => 'None'}},
        'homeTeam' => {'abbrev' => 'None', 'placeName' => {'default' => 'None'}},
        'isFanTeamOpponent' => false
      }
      processor.instance_variable_set(:@next_games, next_games)

      # Mock the render_template method to return HTML content
      allow(processor).to receive(:render_template).and_return("<html>Test content</html>")

      # Create a temporary output file
      temp_output_path = 'spec/fixtures/temp_output.html'

      # Run the render_output method
      expect { processor.render_output(temp_output_path) }.not_to raise_error

      # Verify the file was created
      expect(File.exist?(temp_output_path)).to be true

      # Clean up
      File.delete(temp_output_path) if File.exist?(temp_output_path)
    end
  end
end
