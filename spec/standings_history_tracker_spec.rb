# filepath: /home/runner/work/hockey_bet/hockey_bet/spec/standings_history_tracker_spec.rb

require_relative '../lib/standings_history_tracker'
require 'tempfile'
require 'json'
require 'date'

RSpec.describe StandingsHistoryTracker do
  let(:temp_file) { Tempfile.new(['standings_history', '.json']) }
  let(:tracker) { StandingsHistoryTracker.new(temp_file.path) }
  
  after do
    temp_file.close
    temp_file.unlink
  end
  
  describe '#initialize' do
    it 'creates a new tracker with default path' do
      expect { StandingsHistoryTracker.new }.not_to raise_error
    end
    
    it 'creates a new tracker with custom path' do
      expect { StandingsHistoryTracker.new(temp_file.path) }.not_to raise_error
    end
    
    it 'creates the data file if it does not exist' do
      expect(File.exist?(temp_file.path)).to be true
    end
  end
  
  describe '#load_history' do
    it 'returns empty array for new file' do
      expect(tracker.load_history).to eq([])
    end
    
    it 'loads existing history data' do
      history = [
        { 'date' => '2025-11-01', 'standings' => { 'Fan A' => 10, 'Fan B' => 8 } }
      ]
      File.write(temp_file.path, JSON.generate(history))
      
      expect(tracker.load_history).to eq(history)
    end
    
    it 'returns empty array on parse error' do
      File.write(temp_file.path, 'invalid json')
      
      expect(tracker.load_history).to eq([])
    end
  end
  
  describe '#save_history' do
    it 'saves history data to file' do
      history = [
        { 'date' => '2025-11-01', 'standings' => { 'Fan A' => 10, 'Fan B' => 8 } }
      ]
      
      tracker.save_history(history)
      
      saved_data = JSON.parse(File.read(temp_file.path))
      expect(saved_data).to eq(history)
    end
  end
  
  describe '#record_current_standings' do
    let(:manager_team_map) do
      {
        'COL' => 'Jeff C.',
        'NJD' => 'Travis R.',
        'ANA' => 'Keith R.',
        'SJS' => 'Brian D.',
        'BOS' => 'N/A'
      }
    end
    
    let(:teams) do
      [
        { 'teamAbbrev' => { 'default' => 'COL' }, 'points' => 31 },
        { 'teamAbbrev' => { 'default' => 'NJD' }, 'points' => 27 },
        { 'teamAbbrev' => { 'default' => 'ANA' }, 'points' => 27 },
        { 'teamAbbrev' => { 'default' => 'SJS' }, 'points' => 21 },
        { 'teamAbbrev' => { 'default' => 'BOS' }, 'points' => 30 }
      ]
    end
    
    it 'records current standings for all fans' do
      tracker.record_current_standings(manager_team_map, teams)
      
      history = tracker.load_history
      expect(history.length).to eq(1)
      expect(history[0]['date']).to eq(Date.today.to_s)
      expect(history[0]['season']).to match(/\d{4}-\d{4}/)
      expect(history[0]['standings']['Jeff C.']).to eq(31)
      expect(history[0]['standings']['Travis R.']).to eq(27)
      expect(history[0]['standings']['Brian D.']).to eq(21)
      expect(history[0]['standings']['N/A']).to be_nil
    end
    
    it 'updates existing entry for today' do
      # First recording
      tracker.record_current_standings(manager_team_map, teams)
      
      # Update teams with new points
      updated_teams = teams.map do |team|
        team.merge({ 'points' => team['points'] + 2 })
      end
      
      # Second recording (same day)
      tracker.record_current_standings(manager_team_map, updated_teams)
      
      history = tracker.load_history
      expect(history.length).to eq(1)
      expect(history[0]['standings']['Jeff C.']).to eq(33)
    end
    
    it 'adds new entry for different day' do
      # First recording
      tracker.record_current_standings(manager_team_map, teams)
      
      # Simulate a different day
      allow(Date).to receive(:today).and_return(Date.today + 1)
      
      tracker.record_current_standings(manager_team_map, teams)
      
      history = tracker.load_history
      expect(history.length).to eq(2)
    end
    
    it 'keeps only last 365 days of data' do
      # Create entries for 400 days
      400.times do |i|
        date = (Date.today - 400 + i).to_s
        history = tracker.load_history
        history << {
          'date' => date,
          'standings' => { 'Fan A' => 10 + i }
        }
        tracker.save_history(history)
      end
      
      tracker.record_current_standings(manager_team_map, teams)
      
      history = tracker.load_history
      expect(history.length).to be <= 366 # 365 + today
      
      # Check that oldest entry is within 365 days
      oldest_date = Date.parse(history.first['date'])
      expect(oldest_date).to be >= Date.today - 365
    end
    
    it 'sorts entries by date' do
      # Add entries out of order
      history = [
        { 'date' => '2025-11-03', 'standings' => { 'Fan A' => 12 } },
        { 'date' => '2025-11-01', 'standings' => { 'Fan A' => 10 } },
        { 'date' => '2025-11-02', 'standings' => { 'Fan A' => 11 } }
      ]
      tracker.save_history(history)
      
      tracker.record_current_standings(manager_team_map, teams)
      
      history = tracker.load_history
      dates = history.map { |entry| entry['date'] }
      expect(dates).to eq(dates.sort)
    end
  end
  
  describe '#backfill_seasons' do
    it 'adds season to entries without season field' do
      history = [
        { 'date' => '2024-11-01', 'standings' => { 'Fan A' => 10 } },
        { 'date' => '2025-01-15', 'standings' => { 'Fan A' => 20 } }
      ]
      tracker.save_history(history)
      
      tracker.backfill_seasons
      
      updated_history = tracker.load_history
      expect(updated_history[0]['season']).to eq('2024-2025')
      expect(updated_history[1]['season']).to eq('2024-2025')
    end
    
    it 'does not modify entries that already have season field' do
      history = [
        { 'date' => '2024-11-01', 'season' => '2024-2025', 'standings' => { 'Fan A' => 10 } }
      ]
      tracker.save_history(history)
      
      tracker.backfill_seasons
      
      updated_history = tracker.load_history
      expect(updated_history[0]['season']).to eq('2024-2025')
    end
  end
  
  describe '#get_available_seasons' do
    it 'returns unique seasons from history' do
      history = [
        { 'date' => '2023-11-01', 'season' => '2023-2024', 'standings' => { 'Fan A' => 10 } },
        { 'date' => '2023-12-01', 'season' => '2023-2024', 'standings' => { 'Fan A' => 15 } },
        { 'date' => '2024-11-01', 'season' => '2024-2025', 'standings' => { 'Fan A' => 10 } }
      ]
      tracker.save_history(history)
      
      seasons = tracker.get_available_seasons
      expect(seasons).to eq(['2024-2025', '2023-2024'])
    end
    
    it 'handles entries without season field' do
      history = [
        { 'date' => '2024-11-01', 'standings' => { 'Fan A' => 10 } }
      ]
      tracker.save_history(history)
      
      seasons = tracker.get_available_seasons
      expect(seasons).to eq(['2024-2025'])
    end
  end
  
  describe '#current_season' do
    it 'returns current season based on date' do
      # December is in the first half of the season (started in previous year)
      allow(Date).to receive(:today).and_return(Date.new(2024, 12, 15))
      expect(tracker.current_season).to eq('2024-2025')
    end
    
    it 'returns correct season for summer months' do
      # August is in the off-season, but considered part of next season
      allow(Date).to receive(:today).and_return(Date.new(2024, 8, 15))
      expect(tracker.current_season).to eq('2024-2025')
    end
  end
  
  describe '#get_history_by_season' do
    it 'filters history by season' do
      history = [
        { 'date' => '2023-11-01', 'season' => '2023-2024', 'standings' => { 'Fan A' => 10 } },
        { 'date' => '2024-11-01', 'season' => '2024-2025', 'standings' => { 'Fan A' => 20 } },
        { 'date' => '2024-12-01', 'season' => '2024-2025', 'standings' => { 'Fan A' => 25 } }
      ]
      tracker.save_history(history)
      
      filtered = tracker.get_history_by_season('2024-2025')
      expect(filtered.length).to eq(2)
      expect(filtered[0]['date']).to eq('2024-11-01')
      expect(filtered[1]['date']).to eq('2024-12-01')
    end
    
    it 'handles entries without season field by determining from date' do
      history = [
        { 'date' => '2024-11-01', 'standings' => { 'Fan A' => 10 } }
      ]
      tracker.save_history(history)
      
      filtered = tracker.get_history_by_season('2024-2025')
      expect(filtered.length).to eq(1)
    end
  end
end
