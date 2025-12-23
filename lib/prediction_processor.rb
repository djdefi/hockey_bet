# filepath: /home/runner/work/hockey_bet/hockey_bet/lib/prediction_processor.rb
require_relative 'prediction_tracker'
require_relative 'fan_league_constants'
require_relative 'base_tracker'
require 'json'
require 'fileutils'
require 'set'

# PredictionProcessor processes completed games and calculates prediction accuracy
# Manages prediction results and generates leaderboards
class PredictionProcessor
  include BaseTracker
  
  def initialize(prediction_tracker = nil, results_file = FanLeagueConstants::PREDICTION_RESULTS_FILE, verbose: true)
    @tracker = prediction_tracker || PredictionTracker.new(verbose: verbose)
    initialize_tracker(results_file, verbose: verbose)
  end
  
  # Process a completed game and update prediction results
  # @param game_id [String] Unique game identifier
  # @param winner_abbrev [String] Team abbreviation of the actual winner
  # @return [Hash] Results for this game (fan => result data)
  # @raise [ArgumentError] if game_id or winner_abbrev is empty
  def process_completed_game(game_id, winner_abbrev)
    validate_not_empty!(game_id, "Game ID")
    validate_not_empty!(winner_abbrev, "Winner abbreviation")
    
    predictions = @tracker.get_predictions(game_id)
    results = build_game_results(predictions, winner_abbrev)
    
    # Store results
    save_game_results(game_id, results)
    
    log_info("Processed game #{game_id}: #{winner_abbrev} won, #{results.size} predictions evaluated")
    results
  end
  
  # Calculate prediction accuracy for a specific fan
  # @param fan_name [String] Name of the fan
  # @return [Hash] Accuracy statistics (correct, total, percentage)
  def calculate_accuracy(fan_name)
    results = load_all_results
    correct = 0
    total = 0
    
    results.each do |game_id, game_results|
      next unless game_results[fan_name]
      total += 1
      correct += 1 if game_results[fan_name]['was_correct']
    end
    
    {
      fan_name: fan_name,
      correct: correct,
      total: total,
      percentage: total > 0 ? (correct.to_f / total * 100).round(1) : 0.0
    }
  end
  
  # Get leaderboard sorted by accuracy
  # @return [Array<Hash>] Array of fan stats sorted by accuracy (percentage, then total)
  def get_leaderboard
    # Get all unique fan names from predictions
    fan_names = get_all_fan_names
    
    leaderboard = fan_names.map do |fan_name|
      calculate_accuracy(fan_name)
    end
    
    # Sort by percentage (descending), then by total (descending)
    leaderboard.sort_by { |stat| [-stat[:percentage], -stat[:total]] }
  end
  
  # Get detailed results for a specific fan
  # @param fan_name [String] Name of the fan
  # @return [Hash] Hash of game IDs to detailed results
  def get_fan_results(fan_name)
    results = load_all_results
    fan_results = {}
    
    results.each do |game_id, game_results|
      if game_results[fan_name]
        fan_results[game_id] = game_results[fan_name]
      end
    end
    
    fan_results
  end
  
  # Get results for a specific game
  # @param game_id [String] Unique game identifier
  # @return [Hash] Results for this game (fan => result data)
  def get_game_results(game_id)
    results = load_all_results
    results[game_id] || {}
  end
  
  # Check if a game has been processed
  # @param game_id [String] Unique game identifier
  # @return [Boolean] True if game has been processed
  def game_processed?(game_id)
    results = load_all_results
    results.key?(game_id)
  end
  
  # Get list of all processed game IDs
  # @return [Array<String>] Array of game IDs
  def get_processed_games
    results = load_all_results
    results.keys
  end
  
  # Get current streaks for all fans
  # @return [Hash] Hash of fan names to streak info (current_streak, best_streak)
  def get_streaks
    results = load_all_results
    fan_names = get_all_fan_names
    streaks = {}
    
    fan_names.each do |fan_name|
      streaks[fan_name] = calculate_fan_streak(fan_name, results)
    end
    
    streaks
  end
  
  # Get recent performance for all fans (last N games)
  # @param limit [Integer] Number of recent games to analyze
  # @return [Hash] Hash of fan names to recent stats
  def get_recent_performance(limit = 10)
    results = load_all_results
    fan_names = get_all_fan_names
    recent_stats = {}
    
    fan_names.each do |fan_name|
      fan_games = []
      
      results.each do |game_id, game_results|
        if game_results[fan_name]
          fan_games << {
            game_id: game_id,
            correct: game_results[fan_name]['was_correct'],
            processed_at: game_results[fan_name]['processed_at']
          }
        end
      end
      
      # Sort by processed_at descending and take last N
      recent_games = fan_games.sort_by { |g| g[:processed_at] }.reverse.take(limit)
      
      correct_count = recent_games.count { |g| g[:correct] }
      total_count = recent_games.size
      
      recent_stats[fan_name] = {
        correct: correct_count,
        total: total_count,
        percentage: total_count > 0 ? (correct_count.to_f / total_count * 100).round(1) : 0.0,
        games: recent_games
      }
    end
    
    recent_stats
  end
  
  # Delete results for a specific game (for corrections/testing)
  # @param game_id [String] Unique game identifier
  def delete_game_results(game_id)
    data = load_all_results
    if data.delete(game_id)
      save_all_results(data)
      log_info("Results deleted for game #{game_id}")
    end
  end
  
  # Load all results (exposed for advanced queries)
  # @return [Hash] Complete results data structure
  def load_all_results
    load_data_safe({})
  end
  
  private
  
  # Build results structure from predictions and actual winner
  def build_game_results(predictions, winner_abbrev)
    results = {}
    
    predictions.each do |fan_name, prediction|
      was_correct = prediction['predicted_winner'] == winner_abbrev
      results[fan_name] = {
        'was_correct' => was_correct,
        'predicted_winner' => prediction['predicted_winner'],
        'actual_winner' => winner_abbrev,
        'predicted_at' => prediction['predicted_at'],
        'processed_at' => Time.now.iso8601
      }
    end
    
    results
  end
  
  def save_game_results(game_id, results)
    data = load_all_results
    data[game_id] = results
    save_data_safe(data)
  end
  
  def save_all_results(data)
    save_data_safe(data)
  end
  
  def ensure_results_file_exists
    ensure_data_file_exists({})
  end
  
  def get_all_fan_names
    # Get fan names from both predictions and results
    predictions_data = @tracker.load_data
    results_data = load_all_results
    
    names = Set.new
    
    # From predictions
    predictions_data.each do |game_id, game_predictions|
      names.merge(game_predictions.keys)
    end
    
    # From results
    results_data.each do |game_id, game_results|
      names.merge(game_results.keys)
    end
    
    names.to_a.sort
  end
  
  def calculate_fan_streak(fan_name, results)
    # Get all results for this fan sorted by processed time
    fan_results = []
    
    results.each do |game_id, game_results|
      if game_results[fan_name]
        fan_results << {
          game_id: game_id,
          correct: game_results[fan_name]['was_correct'],
          processed_at: game_results[fan_name]['processed_at']
        }
      end
    end
    
    fan_results.sort_by! { |r| r[:processed_at] }
    
    return { current_streak: 0, best_streak: 0, type: 'none' } if fan_results.empty?
    
    # Calculate current streak (from most recent backwards)
    current_streak = 0
    streak_type = fan_results.last[:correct] ? 'correct' : 'incorrect'
    
    fan_results.reverse_each do |result|
      if result[:correct] == fan_results.last[:correct]
        current_streak += 1
      else
        break
      end
    end
    
    # Calculate best correct streak
    best_streak = 0
    temp_streak = 0
    
    fan_results.each do |result|
      if result[:correct]
        temp_streak += 1
        best_streak = [best_streak, temp_streak].max
      else
        temp_streak = 0
      end
    end
    
    {
      current_streak: current_streak,
      best_streak: best_streak,
      type: streak_type
    }
  end
end
