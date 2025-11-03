# filepath: /home/runner/work/hockey_bet/hockey_bet/spec/historical_stats_tracker_spec.rb
require_relative '../lib/historical_stats_tracker'
require 'tempfile'
require 'fileutils'

RSpec.describe HistoricalStatsTracker do
  let(:temp_file) do
    file = Tempfile.new(['historical_stats', '.json'])
    file.close
    file.path
  end
  
  let(:tracker) { HistoricalStatsTracker.new(temp_file) }
  
  after do
    File.delete(temp_file) if File.exist?(temp_file)
  end
  
  describe '#initialize' do
    it 'creates data file if it does not exist' do
      expect(File.exist?(temp_file)).to be true
    end
    
    it 'initializes with empty data' do
      data = tracker.load_data
      expect(data).to eq({})
    end
  end
  
  describe '#record_season_stats' do
    it 'records stats for a fan in a season' do
      stats = {
        wins: 50,
        losses: 20,
        ot_losses: 5,
        points: 105,
        goals_for: 250,
        goals_against: 200,
        division_rank: 1,
        conference_rank: 2,
        league_rank: 5,
        playoff_wins: 10
      }
      
      tracker.record_season_stats('2023-2024', 'Alice', 'BOS', stats)
      
      data = tracker.load_data
      expect(data['2023-2024']).to be_a(Hash)
      expect(data['2023-2024']['Alice']['team']).to eq('BOS')
      expect(data['2023-2024']['Alice']['wins']).to eq(50)
      expect(data['2023-2024']['Alice']['playoff_wins']).to eq(10)
    end
    
    it 'can record multiple fans in the same season' do
      stats1 = { wins: 50, losses: 20, ot_losses: 5, points: 105,
                 goals_for: 250, goals_against: 200, division_rank: 1,
                 conference_rank: 2, league_rank: 5 }
      stats2 = { wins: 45, losses: 25, ot_losses: 3, points: 93,
                 goals_for: 220, goals_against: 210, division_rank: 2,
                 conference_rank: 3, league_rank: 8 }
      
      tracker.record_season_stats('2023-2024', 'Alice', 'BOS', stats1)
      tracker.record_season_stats('2023-2024', 'Bob', 'FLA', stats2)
      
      data = tracker.load_data
      expect(data['2023-2024'].keys).to contain_exactly('Alice', 'Bob')
    end
  end
  
  describe '#get_fan_seasons' do
    it 'returns all seasons a fan participated in' do
      stats = { wins: 50, losses: 20, ot_losses: 5, points: 105,
               goals_for: 250, goals_against: 200, division_rank: 1,
               conference_rank: 2, league_rank: 5 }
      
      tracker.record_season_stats('2022-2023', 'Alice', 'BOS', stats)
      tracker.record_season_stats('2023-2024', 'Alice', 'BOS', stats)
      tracker.record_season_stats('2024-2025', 'Alice', 'BOS', stats)
      
      seasons = tracker.get_fan_seasons('Alice')
      expect(seasons).to contain_exactly('2022-2023', '2023-2024', '2024-2025')
    end
    
    it 'returns empty array for fan with no history' do
      seasons = tracker.get_fan_seasons('Unknown')
      expect(seasons).to eq([])
    end
  end
  
  describe '#total_playoff_wins' do
    it 'returns sum of playoff wins across all seasons' do
      stats1 = { wins: 50, losses: 20, ot_losses: 5, points: 105,
                goals_for: 250, goals_against: 200, division_rank: 1,
                conference_rank: 2, league_rank: 5, playoff_wins: 8 }
      stats2 = { wins: 45, losses: 25, ot_losses: 3, points: 93,
                goals_for: 220, goals_against: 210, division_rank: 2,
                conference_rank: 3, league_rank: 8, playoff_wins: 12 }
      
      tracker.record_season_stats('2022-2023', 'Alice', 'BOS', stats1)
      tracker.record_season_stats('2023-2024', 'Alice', 'BOS', stats2)
      
      total = tracker.total_playoff_wins('Alice')
      expect(total).to eq(20)
    end
    
    it 'returns 0 for fan with no playoff wins' do
      total = tracker.total_playoff_wins('Unknown')
      expect(total).to eq(0)
    end
  end
  
  describe '#calculate_improvement' do
    it 'calculates improvement between two seasons' do
      stats1 = { wins: 40, losses: 30, ot_losses: 5, points: 85,
                goals_for: 220, goals_against: 230, division_rank: 4,
                conference_rank: 8, league_rank: 18 }
      stats2 = { wins: 50, losses: 20, ot_losses: 5, points: 105,
                goals_for: 250, goals_against: 200, division_rank: 1,
                conference_rank: 2, league_rank: 5 }
      
      tracker.record_season_stats('2022-2023', 'Alice', 'BOS', stats1)
      tracker.record_season_stats('2023-2024', 'Alice', 'BOS', stats2)
      
      improvement = tracker.calculate_improvement('Alice', '2022-2023', '2023-2024')
      
      expect(improvement[:wins_diff]).to eq(10)
      expect(improvement[:points_diff]).to eq(20)
      expect(improvement[:rank_improvement]).to eq(13) # 18 - 5 = 13 spots better
    end
    
    it 'returns nil when seasons do not exist' do
      improvement = tracker.calculate_improvement('Alice', '2022-2023', '2023-2024')
      expect(improvement).to be_nil
    end
  end
  
  describe '#current_season' do
    it 'returns current season in YYYY-YYYY format' do
      season = tracker.current_season
      expect(season).to match(/^\d{4}-\d{4}$/)
    end
    
    it 'uses correct year based on month' do
      # Mock different dates to test logic
      allow(Date).to receive(:today).and_return(Date.new(2024, 10, 15))
      expect(tracker.current_season).to eq('2024-2025')
      
      allow(Date).to receive(:today).and_return(Date.new(2025, 3, 15))
      expect(tracker.current_season).to eq('2024-2025')
    end
  end
end
