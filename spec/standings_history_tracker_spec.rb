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
end
