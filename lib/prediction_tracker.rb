# filepath: /home/runner/work/hockey_bet/hockey_bet/lib/prediction_tracker.rb
require 'json'
require 'fileutils'
require 'time'
require_relative 'fan_league_constants'
require_relative 'base_tracker'

# PredictionTracker manages game predictions for the 13-person fan league
# Uses honor system with hardcoded fan names (no authentication)
# Stores predictions in JSON file for simplicity and GitHub Pages compatibility
class PredictionTracker
  include BaseTracker
  
  def initialize(data_file = FanLeagueConstants::PREDICTIONS_FILE, verbose: true)
    initialize_tracker(data_file, verbose: verbose)
  end
  
  # Store a prediction (no authentication, just fan name from dropdown)
  # @param fan_name [String] Name of the fan making the prediction
  # @param game_id [String] Unique game identifier
  # @param predicted_winner [String] Team abbreviation of predicted winner
  # @param predicted_at [Time] Timestamp of prediction (defaults to now)
  # @raise [ArgumentError] if fan_name, game_id, or predicted_winner is empty
  def store_prediction(fan_name, game_id, predicted_winner, predicted_at = Time.now)
    validate_not_empty!(fan_name, "Fan name")
    validate_not_empty!(game_id, "Game ID")
    validate_not_empty!(predicted_winner, "Predicted winner")
    
    data = load_data
    
    # Structure: { "game_id": { "fan_name": { "predicted_winner": "SJS", "predicted_at": "..." }}}
    data[game_id] ||= {}
    data[game_id][fan_name] = {
      'predicted_winner' => predicted_winner,
      'predicted_at' => predicted_at.iso8601
    }
    
    save_data(data)
    
    log_info("Prediction stored: #{fan_name} → #{predicted_winner} for game #{game_id}")
  end
  
  # Get all predictions for a specific game
  # @param game_id [String] Unique game identifier
  # @return [Hash] Hash of fan names to their predictions for this game
  def get_predictions(game_id)
    data = load_data
    data[game_id] || {}
  end
  
  # Get all predictions made by a specific fan
  # @param fan_name [String] Name of the fan
  # @return [Hash] Hash of game IDs to predictions made by this fan
  def get_fan_predictions(fan_name)
    data = load_data
    result = {}
    
    data.each do |game_id, predictions|
      if predictions[fan_name]
        result[game_id] = predictions[fan_name]
      end
    end
    
    result
  end
  
  # Get prediction statistics for all fans
  # @return [Hash] Hash of fan names to their prediction stats (total count, games list)
  def get_prediction_stats
    data = load_data
    stats = {}
    
    # Count total predictions per fan
    data.each do |game_id, predictions|
      predictions.each do |fan_name, prediction|
        stats[fan_name] ||= { total: 0, games: [] }
        stats[fan_name][:total] += 1
        stats[fan_name][:games] << game_id
      end
    end
    
    stats
  end
  
  # Get all game IDs that have predictions
  # @return [Array<String>] Array of game IDs
  def get_games_with_predictions
    data = load_data
    data.keys
  end
  
  # Check if a fan has already predicted for a specific game
  # @param fan_name [String] Name of the fan
  # @param game_id [String] Unique game identifier
  # @return [Boolean] True if fan has predicted, false otherwise
  def has_predicted?(fan_name, game_id)
    data = load_data
    data.dig(game_id, fan_name) != nil
  end
  
  # Delete a prediction (for testing or corrections)
  # @param fan_name [String] Name of the fan
  # @param game_id [String] Unique game identifier
  def delete_prediction(fan_name, game_id)
    data = load_data
    
    if data[game_id]
      data[game_id].delete(fan_name)
      
      # Remove game entry if no predictions left
      data.delete(game_id) if data[game_id].empty?
      
      save_data(data)
      log_info("Prediction deleted: #{fan_name} for game #{game_id}")
    end
  end
  
  # Get count of predictions per game
  # @return [Hash] Hash of game IDs to prediction counts
  def get_prediction_counts
    data = load_data
    counts = {}
    
    data.each do |game_id, predictions|
      counts[game_id] = predictions.size
    end
    
    counts
  end
  
  # Load all prediction data (exposed for processor class)
  # @return [Hash] Complete prediction data structure
  def load_data
    load_data_safe({})
  end
  
  private
  
  def save_data(data)
    save_data_safe(data)
  end
end
