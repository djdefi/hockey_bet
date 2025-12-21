# filepath: /home/runner/work/hockey_bet/hockey_bet/spec/prediction_tracker_spec.rb

require_relative '../lib/prediction_tracker'
require 'tempfile'
require 'json'
require 'time'

RSpec.describe PredictionTracker do
  let(:temp_file) { Tempfile.new(['predictions', '.json']) }
  let(:tracker) { PredictionTracker.new(temp_file.path) }
  
  after do
    temp_file.close
    temp_file.unlink
  end
  
  describe '#initialize' do
    it 'creates a new tracker with default path' do
      expect { PredictionTracker.new }.not_to raise_error
    end
    
    it 'creates a new tracker with custom path' do
      expect { PredictionTracker.new(temp_file.path) }.not_to raise_error
    end
    
    it 'creates the data file if it does not exist' do
      expect(File.exist?(temp_file.path)).to be true
    end
    
    it 'initializes with empty data' do
      data = tracker.load_data
      expect(data).to eq({})
    end
  end
  
  describe '#store_prediction' do
    it 'stores a prediction successfully' do
      tracker.store_prediction('Jeff C.', 'game_123', 'COL')
      
      data = tracker.load_data
      expect(data['game_123']['Jeff C.']['predicted_winner']).to eq('COL')
      expect(data['game_123']['Jeff C.']['predicted_at']).to be_a(String)
    end
    
    it 'stores predictions with custom timestamp' do
      custom_time = Time.parse('2025-12-15 18:00:00 UTC')
      tracker.store_prediction('Brian D.', 'game_456', 'SJS', custom_time)
      
      data = tracker.load_data
      expect(data['game_456']['Brian D.']['predicted_at']).to eq(custom_time.iso8601)
    end
    
    it 'allows multiple fans to predict same game' do
      tracker.store_prediction('Jeff C.', 'game_123', 'COL')
      tracker.store_prediction('Brian D.', 'game_123', 'SJS')
      tracker.store_prediction('Travis R.', 'game_123', 'COL')
      
      predictions = tracker.get_predictions('game_123')
      expect(predictions.size).to eq(3)
      expect(predictions['Jeff C.']['predicted_winner']).to eq('COL')
      expect(predictions['Brian D.']['predicted_winner']).to eq('SJS')
      expect(predictions['Travis R.']['predicted_winner']).to eq('COL')
    end
    
    it 'updates existing prediction if fan predicts same game again' do
      tracker.store_prediction('Jeff C.', 'game_123', 'COL')
      tracker.store_prediction('Jeff C.', 'game_123', 'SJS')
      
      predictions = tracker.get_predictions('game_123')
      expect(predictions.size).to eq(1)
      expect(predictions['Jeff C.']['predicted_winner']).to eq('SJS')
    end
    
    it 'handles special characters in fan names' do
      tracker.store_prediction("Ryan T. O'Brien", 'game_123', 'MIN')
      
      predictions = tracker.get_predictions('game_123')
      expect(predictions["Ryan T. O'Brien"]['predicted_winner']).to eq('MIN')
    end
  end
  
  describe '#get_predictions' do
    before do
      tracker.store_prediction('Jeff C.', 'game_123', 'COL')
      tracker.store_prediction('Brian D.', 'game_123', 'SJS')
      tracker.store_prediction('Travis R.', 'game_456', 'NJD')
    end
    
    it 'returns all predictions for a specific game' do
      predictions = tracker.get_predictions('game_123')
      expect(predictions.size).to eq(2)
      expect(predictions.keys).to contain_exactly('Jeff C.', 'Brian D.')
    end
    
    it 'returns empty hash for game with no predictions' do
      predictions = tracker.get_predictions('game_999')
      expect(predictions).to eq({})
    end
    
    it 'returns predictions with full data structure' do
      predictions = tracker.get_predictions('game_123')
      jeff_pred = predictions['Jeff C.']
      
      expect(jeff_pred).to have_key('predicted_winner')
      expect(jeff_pred).to have_key('predicted_at')
      expect(jeff_pred['predicted_winner']).to eq('COL')
    end
  end
  
  describe '#get_fan_predictions' do
    before do
      tracker.store_prediction('Jeff C.', 'game_123', 'COL')
      tracker.store_prediction('Jeff C.', 'game_456', 'COL')
      tracker.store_prediction('Brian D.', 'game_123', 'SJS')
      tracker.store_prediction('Jeff C.', 'game_789', 'COL')
    end
    
    it 'returns all predictions by a specific fan' do
      predictions = tracker.get_fan_predictions('Jeff C.')
      expect(predictions.size).to eq(3)
      expect(predictions.keys).to contain_exactly('game_123', 'game_456', 'game_789')
    end
    
    it 'returns empty hash for fan with no predictions' do
      predictions = tracker.get_fan_predictions('Sean R.')
      expect(predictions).to eq({})
    end
    
    it 'returns predictions with full data structure' do
      predictions = tracker.get_fan_predictions('Jeff C.')
      game_123_pred = predictions['game_123']
      
      expect(game_123_pred).to have_key('predicted_winner')
      expect(game_123_pred).to have_key('predicted_at')
      expect(game_123_pred['predicted_winner']).to eq('COL')
    end
  end
  
  describe '#get_prediction_stats' do
    before do
      tracker.store_prediction('Jeff C.', 'game_123', 'COL')
      tracker.store_prediction('Jeff C.', 'game_456', 'COL')
      tracker.store_prediction('Jeff C.', 'game_789', 'COL')
      tracker.store_prediction('Brian D.', 'game_123', 'SJS')
      tracker.store_prediction('Brian D.', 'game_456', 'SJS')
      tracker.store_prediction('Travis R.', 'game_123', 'NJD')
    end
    
    it 'returns stats for all fans who have predicted' do
      stats = tracker.get_prediction_stats
      expect(stats.size).to eq(3)
      expect(stats.keys).to contain_exactly('Jeff C.', 'Brian D.', 'Travis R.')
    end
    
    it 'counts total predictions correctly' do
      stats = tracker.get_prediction_stats
      expect(stats['Jeff C.'][:total]).to eq(3)
      expect(stats['Brian D.'][:total]).to eq(2)
      expect(stats['Travis R.'][:total]).to eq(1)
    end
    
    it 'lists games predicted by each fan' do
      stats = tracker.get_prediction_stats
      expect(stats['Jeff C.'][:games]).to contain_exactly('game_123', 'game_456', 'game_789')
      expect(stats['Brian D.'][:games]).to contain_exactly('game_123', 'game_456')
    end
    
    it 'returns empty hash when no predictions exist' do
      empty_tracker = PredictionTracker.new(Tempfile.new(['empty', '.json']).path)
      stats = empty_tracker.get_prediction_stats
      expect(stats).to eq({})
    end
  end
  
  describe '#get_games_with_predictions' do
    before do
      tracker.store_prediction('Jeff C.', 'game_123', 'COL')
      tracker.store_prediction('Brian D.', 'game_456', 'SJS')
      tracker.store_prediction('Travis R.', 'game_789', 'NJD')
    end
    
    it 'returns all game IDs that have predictions' do
      games = tracker.get_games_with_predictions
      expect(games).to contain_exactly('game_123', 'game_456', 'game_789')
    end
    
    it 'returns empty array when no predictions exist' do
      empty_tracker = PredictionTracker.new(Tempfile.new(['empty', '.json']).path)
      games = empty_tracker.get_games_with_predictions
      expect(games).to eq([])
    end
  end
  
  describe '#has_predicted?' do
    before do
      tracker.store_prediction('Jeff C.', 'game_123', 'COL')
      tracker.store_prediction('Brian D.', 'game_456', 'SJS')
    end
    
    it 'returns true when fan has predicted for game' do
      expect(tracker.has_predicted?('Jeff C.', 'game_123')).to be true
      expect(tracker.has_predicted?('Brian D.', 'game_456')).to be true
    end
    
    it 'returns false when fan has not predicted for game' do
      expect(tracker.has_predicted?('Jeff C.', 'game_456')).to be false
      expect(tracker.has_predicted?('Travis R.', 'game_123')).to be false
    end
    
    it 'returns false for non-existent game' do
      expect(tracker.has_predicted?('Jeff C.', 'game_999')).to be false
    end
  end
  
  describe '#delete_prediction' do
    before do
      tracker.store_prediction('Jeff C.', 'game_123', 'COL')
      tracker.store_prediction('Brian D.', 'game_123', 'SJS')
      tracker.store_prediction('Travis R.', 'game_456', 'NJD')
    end
    
    it 'deletes a specific prediction' do
      tracker.delete_prediction('Jeff C.', 'game_123')
      
      expect(tracker.has_predicted?('Jeff C.', 'game_123')).to be false
      expect(tracker.has_predicted?('Brian D.', 'game_123')).to be true
    end
    
    it 'removes game entry when last prediction is deleted' do
      tracker.delete_prediction('Travis R.', 'game_456')
      
      games = tracker.get_games_with_predictions
      expect(games).not_to include('game_456')
    end
    
    it 'handles deleting non-existent prediction gracefully' do
      expect {
        tracker.delete_prediction('Sean R.', 'game_999')
      }.not_to raise_error
    end
    
    it 'keeps other predictions when deleting one' do
      tracker.delete_prediction('Jeff C.', 'game_123')
      
      predictions = tracker.get_predictions('game_123')
      expect(predictions.size).to eq(1)
      expect(predictions['Brian D.']).not_to be_nil
    end
  end
  
  describe '#get_prediction_counts' do
    before do
      tracker.store_prediction('Jeff C.', 'game_123', 'COL')
      tracker.store_prediction('Brian D.', 'game_123', 'SJS')
      tracker.store_prediction('Travis R.', 'game_123', 'NJD')
      tracker.store_prediction('Jeff C.', 'game_456', 'COL')
    end
    
    it 'returns count of predictions per game' do
      counts = tracker.get_prediction_counts
      expect(counts['game_123']).to eq(3)
      expect(counts['game_456']).to eq(1)
    end
    
    it 'returns empty hash when no predictions exist' do
      empty_tracker = PredictionTracker.new(Tempfile.new(['empty', '.json']).path)
      counts = empty_tracker.get_prediction_counts
      expect(counts).to eq({})
    end
  end
  
  describe '#load_data' do
    it 'returns empty hash for new file' do
      expect(tracker.load_data).to eq({})
    end
    
    it 'loads existing prediction data' do
      data = {
        'game_123' => {
          'Jeff C.' => {
            'predicted_winner' => 'COL',
            'predicted_at' => '2025-12-15T18:00:00Z'
          }
        }
      }
      File.write(temp_file.path, JSON.generate(data))
      
      expect(tracker.load_data).to eq(data)
    end
    
    it 'returns empty hash on parse error' do
      File.write(temp_file.path, 'invalid json')
      
      expect(tracker.load_data).to eq({})
    end
    
    it 'handles empty file gracefully' do
      File.write(temp_file.path, '')
      
      expect(tracker.load_data).to eq({})
    end
  end
  
  describe 'data persistence' do
    it 'persists predictions across multiple operations' do
      tracker.store_prediction('Jeff C.', 'game_123', 'COL')
      tracker.store_prediction('Brian D.', 'game_456', 'SJS')
      
      # Create new tracker instance pointing to same file
      new_tracker = PredictionTracker.new(temp_file.path)
      
      predictions_123 = new_tracker.get_predictions('game_123')
      predictions_456 = new_tracker.get_predictions('game_456')
      
      expect(predictions_123['Jeff C.']['predicted_winner']).to eq('COL')
      expect(predictions_456['Brian D.']['predicted_winner']).to eq('SJS')
    end
    
    it 'maintains data integrity after multiple updates' do
      tracker.store_prediction('Jeff C.', 'game_123', 'COL')
      tracker.store_prediction('Jeff C.', 'game_123', 'SJS')
      tracker.store_prediction('Jeff C.', 'game_123', 'COL')
      
      predictions = tracker.get_predictions('game_123')
      expect(predictions.size).to eq(1)
      expect(predictions['Jeff C.']['predicted_winner']).to eq('COL')
    end
  end
  
  describe 'honor system validation' do
    it 'allows same fan name to be used without authentication' do
      # Simulates two different "Jeff C." predictions (honor system)
      tracker.store_prediction('Jeff C.', 'game_123', 'COL')
      tracker.store_prediction('Jeff C.', 'game_456', 'SJS')
      
      expect(tracker.get_fan_predictions('Jeff C.').size).to eq(2)
    end
    
    it 'does not validate fan names against a roster' do
      # System accepts any name (honor system)
      tracker.store_prediction('Random Person', 'game_123', 'COL')
      
      expect(tracker.has_predicted?('Random Person', 'game_123')).to be true
    end
  end
end
