# filepath: /home/runner/work/hockey_bet/hockey_bet/spec/prediction_processor_spec.rb

require_relative '../lib/prediction_processor'
require_relative '../lib/prediction_tracker'
require 'tempfile'
require 'json'
require 'time'

RSpec.describe PredictionProcessor do
  let(:temp_predictions_file) { Tempfile.new(['predictions', '.json']) }
  let(:temp_results_file) { Tempfile.new(['results', '.json']) }
  let(:tracker) { PredictionTracker.new(temp_predictions_file.path) }
  let(:processor) { PredictionProcessor.new(tracker, temp_results_file.path) }
  
  after do
    temp_predictions_file.close
    temp_predictions_file.unlink
    temp_results_file.close
    temp_results_file.unlink
  end
  
  describe '#initialize' do
    it 'creates a new processor with default tracker' do
      expect { PredictionProcessor.new }.not_to raise_error
    end
    
    it 'creates a new processor with custom tracker and results file' do
      expect { PredictionProcessor.new(tracker, temp_results_file.path) }.not_to raise_error
    end
    
    it 'creates the results file if it does not exist' do
      expect(File.exist?(temp_results_file.path)).to be true
    end
  end
  
  describe '#process_completed_game' do
    before do
      tracker.store_prediction('Jeff C.', 'game_123', 'COL')
      tracker.store_prediction('Brian D.', 'game_123', 'SJS')
      tracker.store_prediction('Travis R.', 'game_123', 'COL')
    end
    
    it 'processes game results correctly' do
      results = processor.process_completed_game('game_123', 'COL')
      
      expect(results.size).to eq(3)
      expect(results['Jeff C.']['was_correct']).to be true
      expect(results['Brian D.']['was_correct']).to be false
      expect(results['Travis R.']['was_correct']).to be true
    end
    
    it 'stores winner information' do
      results = processor.process_completed_game('game_123', 'COL')
      
      expect(results['Jeff C.']['actual_winner']).to eq('COL')
      expect(results['Jeff C.']['predicted_winner']).to eq('COL')
      expect(results['Brian D.']['predicted_winner']).to eq('SJS')
    end
    
    it 'includes timestamps' do
      results = processor.process_completed_game('game_123', 'COL')
      
      expect(results['Jeff C.']).to have_key('predicted_at')
      expect(results['Jeff C.']).to have_key('processed_at')
      expect(results['Jeff C.']['processed_at']).to match(/\d{4}-\d{2}-\d{2}T/)
    end
    
    it 'persists results to file' do
      processor.process_completed_game('game_123', 'COL')
      
      # Create new processor to load from file
      new_processor = PredictionProcessor.new(tracker, temp_results_file.path)
      results = new_processor.get_game_results('game_123')
      
      expect(results['Jeff C.']['was_correct']).to be true
    end
    
    it 'handles games with no predictions' do
      results = processor.process_completed_game('game_999', 'COL')
      
      expect(results).to eq({})
    end
  end
  
  describe '#calculate_accuracy' do
    before do
      # Setup predictions
      tracker.store_prediction('Jeff C.', 'game_1', 'COL')
      tracker.store_prediction('Jeff C.', 'game_2', 'COL')
      tracker.store_prediction('Jeff C.', 'game_3', 'SJS')
      tracker.store_prediction('Jeff C.', 'game_4', 'COL')
      
      # Process results (3 correct, 1 incorrect)
      processor.process_completed_game('game_1', 'COL')  # correct
      processor.process_completed_game('game_2', 'COL')  # correct
      processor.process_completed_game('game_3', 'NJD')  # incorrect
      processor.process_completed_game('game_4', 'COL')  # correct
    end
    
    it 'calculates accuracy correctly' do
      accuracy = processor.calculate_accuracy('Jeff C.')
      
      expect(accuracy[:fan_name]).to eq('Jeff C.')
      expect(accuracy[:correct]).to eq(3)
      expect(accuracy[:total]).to eq(4)
      expect(accuracy[:percentage]).to eq(75.0)
    end
    
    it 'handles fan with no predictions' do
      accuracy = processor.calculate_accuracy('Sean R.')
      
      expect(accuracy[:correct]).to eq(0)
      expect(accuracy[:total]).to eq(0)
      expect(accuracy[:percentage]).to eq(0.0)
    end
    
    it 'calculates 100% accuracy' do
      tracker.store_prediction('Brian D.', 'game_1', 'COL')
      tracker.store_prediction('Brian D.', 'game_2', 'COL')
      processor.process_completed_game('game_1', 'COL')
      processor.process_completed_game('game_2', 'COL')
      
      accuracy = processor.calculate_accuracy('Brian D.')
      expect(accuracy[:percentage]).to eq(100.0)
    end
    
    it 'calculates 0% accuracy' do
      tracker.store_prediction('Travis R.', 'game_1', 'SJS')
      tracker.store_prediction('Travis R.', 'game_2', 'SJS')
      processor.process_completed_game('game_1', 'COL')
      processor.process_completed_game('game_2', 'COL')
      
      accuracy = processor.calculate_accuracy('Travis R.')
      expect(accuracy[:percentage]).to eq(0.0)
    end
  end
  
  describe '#get_leaderboard' do
    before do
      # Jeff C.: 3/4 = 75%
      tracker.store_prediction('Jeff C.', 'game_1', 'COL')
      tracker.store_prediction('Jeff C.', 'game_2', 'COL')
      tracker.store_prediction('Jeff C.', 'game_3', 'SJS')
      tracker.store_prediction('Jeff C.', 'game_4', 'COL')
      
      # Brian D.: 2/2 = 100%
      tracker.store_prediction('Brian D.', 'game_1', 'COL')
      tracker.store_prediction('Brian D.', 'game_2', 'COL')
      
      # Travis R.: 1/3 = 33.3%
      tracker.store_prediction('Travis R.', 'game_1', 'SJS')
      tracker.store_prediction('Travis R.', 'game_2', 'SJS')
      tracker.store_prediction('Travis R.', 'game_3', 'NJD')
      
      processor.process_completed_game('game_1', 'COL')
      processor.process_completed_game('game_2', 'COL')
      processor.process_completed_game('game_3', 'NJD')
      processor.process_completed_game('game_4', 'COL')
    end
    
    it 'returns leaderboard sorted by accuracy' do
      leaderboard = processor.get_leaderboard
      
      expect(leaderboard.size).to eq(3)
      expect(leaderboard[0][:fan_name]).to eq('Brian D.')  # 100%
      expect(leaderboard[1][:fan_name]).to eq('Jeff C.')   # 75%
      expect(leaderboard[2][:fan_name]).to eq('Travis R.') # 33.3%
    end
    
    it 'sorts by total when percentage is tied' do
      # Setup: Both have 50% but different totals
      # Clear previous test data by creating new instances
      temp_pred_2 = Tempfile.new(['pred2', '.json'])
      temp_res_2 = Tempfile.new(['res2', '.json'])
      tracker_2 = PredictionTracker.new(temp_pred_2.path)
      processor_2 = PredictionProcessor.new(tracker_2, temp_res_2.path)
      
      # Sean R.: 2 correct out of 4 = 50%
      tracker_2.store_prediction('Sean R.', 'game_1', 'COL')
      tracker_2.store_prediction('Sean R.', 'game_2', 'COL')
      tracker_2.store_prediction('Sean R.', 'game_3', 'COL')
      tracker_2.store_prediction('Sean R.', 'game_4', 'COL')
      
      # Ryan B.: 1 correct out of 2 = 50%
      tracker_2.store_prediction('Ryan B.', 'game_1', 'COL')
      tracker_2.store_prediction('Ryan B.', 'game_2', 'COL')
      
      # Process: games 1 and 3 are COL wins, games 2 and 4 are SJS wins
      processor_2.process_completed_game('game_1', 'COL')
      processor_2.process_completed_game('game_2', 'SJS')
      processor_2.process_completed_game('game_3', 'COL')
      processor_2.process_completed_game('game_4', 'SJS')
      
      leaderboard = processor_2.get_leaderboard
      
      # Both have 50%, but Sean has 4 predictions vs Ryan's 2
      sean_stats = leaderboard.find { |s| s[:fan_name] == 'Sean R.' }
      ryan_stats = leaderboard.find { |s| s[:fan_name] == 'Ryan B.' }
      
      expect(sean_stats[:percentage]).to eq(50.0)
      expect(ryan_stats[:percentage]).to eq(50.0)
      expect(sean_stats[:total]).to eq(4)
      expect(ryan_stats[:total]).to eq(2)
      
      sean_index = leaderboard.index { |s| s[:fan_name] == 'Sean R.' }
      ryan_index = leaderboard.index { |s| s[:fan_name] == 'Ryan B.' }
      
      expect(sean_index).to be < ryan_index
      
      temp_pred_2.close
      temp_pred_2.unlink
      temp_res_2.close
      temp_res_2.unlink
    end
    
    it 'returns empty array when no predictions exist' do
      empty_tracker = PredictionTracker.new(Tempfile.new(['empty', '.json']).path)
      empty_processor = PredictionProcessor.new(empty_tracker, Tempfile.new(['empty_results', '.json']).path)
      
      leaderboard = empty_processor.get_leaderboard
      expect(leaderboard).to eq([])
    end
  end
  
  describe '#get_fan_results' do
    before do
      tracker.store_prediction('Jeff C.', 'game_1', 'COL')
      tracker.store_prediction('Jeff C.', 'game_2', 'SJS')
      
      processor.process_completed_game('game_1', 'COL')
      processor.process_completed_game('game_2', 'COL')
    end
    
    it 'returns all results for a specific fan' do
      results = processor.get_fan_results('Jeff C.')
      
      expect(results.size).to eq(2)
      expect(results).to have_key('game_1')
      expect(results).to have_key('game_2')
    end
    
    it 'includes correctness information' do
      results = processor.get_fan_results('Jeff C.')
      
      expect(results['game_1']['was_correct']).to be true
      expect(results['game_2']['was_correct']).to be false
    end
    
    it 'returns empty hash for fan with no results' do
      results = processor.get_fan_results('Brian D.')
      expect(results).to eq({})
    end
  end
  
  describe '#get_game_results' do
    before do
      tracker.store_prediction('Jeff C.', 'game_1', 'COL')
      tracker.store_prediction('Brian D.', 'game_1', 'SJS')
      
      processor.process_completed_game('game_1', 'COL')
    end
    
    it 'returns results for a specific game' do
      results = processor.get_game_results('game_1')
      
      expect(results.size).to eq(2)
      expect(results).to have_key('Jeff C.')
      expect(results).to have_key('Brian D.')
    end
    
    it 'returns empty hash for unprocessed game' do
      results = processor.get_game_results('game_999')
      expect(results).to eq({})
    end
  end
  
  describe '#game_processed?' do
    before do
      tracker.store_prediction('Jeff C.', 'game_1', 'COL')
      processor.process_completed_game('game_1', 'COL')
    end
    
    it 'returns true for processed game' do
      expect(processor.game_processed?('game_1')).to be true
    end
    
    it 'returns false for unprocessed game' do
      expect(processor.game_processed?('game_999')).to be false
    end
  end
  
  describe '#get_processed_games' do
    before do
      tracker.store_prediction('Jeff C.', 'game_1', 'COL')
      tracker.store_prediction('Jeff C.', 'game_2', 'SJS')
      tracker.store_prediction('Jeff C.', 'game_3', 'NJD')
      
      processor.process_completed_game('game_1', 'COL')
      processor.process_completed_game('game_2', 'COL')
    end
    
    it 'returns list of processed game IDs' do
      games = processor.get_processed_games
      
      expect(games).to contain_exactly('game_1', 'game_2')
    end
    
    it 'returns empty array when no games processed' do
      empty_processor = PredictionProcessor.new(tracker, Tempfile.new(['empty', '.json']).path)
      games = empty_processor.get_processed_games
      
      expect(games).to eq([])
    end
  end
  
  describe '#get_streaks' do
    before do
      # Jeff C: W, W, L, W, W (current: 2 correct, best: 2)
      tracker.store_prediction('Jeff C.', 'game_1', 'COL')
      tracker.store_prediction('Jeff C.', 'game_2', 'COL')
      tracker.store_prediction('Jeff C.', 'game_3', 'SJS')
      tracker.store_prediction('Jeff C.', 'game_4', 'COL')
      tracker.store_prediction('Jeff C.', 'game_5', 'COL')
      
      sleep(0.01) # Ensure different timestamps
      processor.process_completed_game('game_1', 'COL')
      sleep(0.01)
      processor.process_completed_game('game_2', 'COL')
      sleep(0.01)
      processor.process_completed_game('game_3', 'NJD')
      sleep(0.01)
      processor.process_completed_game('game_4', 'COL')
      sleep(0.01)
      processor.process_completed_game('game_5', 'COL')
    end
    
    it 'calculates current streak correctly' do
      streaks = processor.get_streaks
      
      expect(streaks['Jeff C.'][:current_streak]).to eq(2)
      expect(streaks['Jeff C.'][:type]).to eq('correct')
    end
    
    it 'calculates best streak correctly' do
      streaks = processor.get_streaks
      
      expect(streaks['Jeff C.'][:best_streak]).to eq(2)
    end
    
    it 'handles incorrect streak' do
      tracker.store_prediction('Brian D.', 'game_1', 'SJS')
      tracker.store_prediction('Brian D.', 'game_2', 'SJS')
      processor.process_completed_game('game_1', 'COL')
      processor.process_completed_game('game_2', 'COL')
      
      streaks = processor.get_streaks
      
      expect(streaks['Brian D.'][:current_streak]).to eq(2)
      expect(streaks['Brian D.'][:type]).to eq('incorrect')
      expect(streaks['Brian D.'][:best_streak]).to eq(0)
    end
  end
  
  describe '#get_recent_performance' do
    before do
      # Create 15 predictions (will only analyze last 10 by default)
      15.times do |i|
        game_id = "game_#{i + 1}"
        tracker.store_prediction('Jeff C.', game_id, 'COL')
        sleep(0.01) # Ensure different timestamps
        
        # Make last 8 correct, first 7 incorrect
        winner = i >= 7 ? 'COL' : 'SJS'
        processor.process_completed_game(game_id, winner)
      end
    end
    
    it 'analyzes recent performance (last 10 games)' do
      stats = processor.get_recent_performance(10)
      
      expect(stats['Jeff C.'][:total]).to eq(10)
      expect(stats['Jeff C.'][:correct]).to eq(8)  # Last 10 include 8 correct
      expect(stats['Jeff C.'][:percentage]).to eq(80.0)
    end
    
    it 'can analyze different limits' do
      stats = processor.get_recent_performance(5)
      
      expect(stats['Jeff C.'][:total]).to eq(5)
      expect(stats['Jeff C.'][:correct]).to eq(5)  # Last 5 are all correct
      expect(stats['Jeff C.'][:percentage]).to eq(100.0)
    end
    
    it 'includes game details' do
      stats = processor.get_recent_performance(3)
      
      expect(stats['Jeff C.'][:games].size).to eq(3)
      expect(stats['Jeff C.'][:games][0]).to have_key(:game_id)
      expect(stats['Jeff C.'][:games][0]).to have_key(:correct)
    end
  end
  
  describe '#delete_game_results' do
    before do
      tracker.store_prediction('Jeff C.', 'game_1', 'COL')
      processor.process_completed_game('game_1', 'COL')
    end
    
    it 'deletes results for a specific game' do
      processor.delete_game_results('game_1')
      
      expect(processor.game_processed?('game_1')).to be false
    end
    
    it 'handles deleting non-existent game gracefully' do
      expect {
        processor.delete_game_results('game_999')
      }.not_to raise_error
    end
  end
  
  describe '#load_all_results' do
    it 'returns empty hash for new file' do
      expect(processor.load_all_results).to eq({})
    end
    
    it 'loads existing results' do
      tracker.store_prediction('Jeff C.', 'game_1', 'COL')
      processor.process_completed_game('game_1', 'COL')
      
      results = processor.load_all_results
      expect(results).to have_key('game_1')
    end
    
    it 'returns empty hash on parse error' do
      File.write(temp_results_file.path, 'invalid json')
      
      expect(processor.load_all_results).to eq({})
    end
  end
end
