# filepath: /home/runner/work/hockey_bet/hockey_bet/lib/historical_stats_tracker.rb
require 'json'
require 'fileutils'
require 'date'

class HistoricalStatsTracker
  attr_reader :data_file
  
  def initialize(data_file = 'data/historical_stats.json')
    @data_file = data_file
    ensure_data_file_exists
  end
  
  # Load historical data from JSON file
  def load_data
    return {} unless File.exist?(@data_file)
    
    JSON.parse(File.read(@data_file))
  rescue JSON::ParserError => e
    puts "Warning: Error parsing historical data: #{e.message}"
    {}
  end
  
  # Save historical data to JSON file
  def save_data(data)
    FileUtils.mkdir_p(File.dirname(@data_file))
    File.write(@data_file, JSON.pretty_generate(data))
  end
  
  # Record current season stats for a fan's team
  def record_season_stats(season, fan, team_abbrev, stats)
    data = load_data
    data[season] ||= {}
    data[season][fan] = {
      'team' => team_abbrev,
      'wins' => stats[:wins],
      'losses' => stats[:losses],
      'ot_losses' => stats[:ot_losses],
      'points' => stats[:points],
      'goals_for' => stats[:goals_for],
      'goals_against' => stats[:goals_against],
      'division_rank' => stats[:division_rank],
      'conference_rank' => stats[:conference_rank],
      'league_rank' => stats[:league_rank],
      'playoff_wins' => stats[:playoff_wins] || 0,
      'recorded_at' => Time.now.to_s
    }
    save_data(data)
  end
  
  # Get all seasons a fan has participated in
  def get_fan_seasons(fan)
    data = load_data
    seasons = []
    data.each do |season, fans|
      seasons << season if fans.key?(fan)
    end
    seasons.sort
  end
  
  # Get a fan's stats for a specific season
  def get_season_stats(season, fan)
    data = load_data
    data.dig(season, fan)
  end
  
  # Get all stats for a fan across all seasons
  def get_fan_history(fan)
    data = load_data
    history = {}
    data.each do |season, fans|
      history[season] = fans[fan] if fans.key?(fan)
    end
    history
  end
  
  # Calculate total playoff wins across all seasons for a fan
  def total_playoff_wins(fan)
    history = get_fan_history(fan)
    history.values.sum { |stats| stats['playoff_wins'] || 0 }
  end
  
  # Calculate improvement between two seasons
  def calculate_improvement(fan, season1, season2)
    stats1 = get_season_stats(season1, fan)
    stats2 = get_season_stats(season2, fan)
    
    return nil unless stats1 && stats2
    
    {
      wins_diff: stats2['wins'] - stats1['wins'],
      points_diff: stats2['points'] - stats1['points'],
      rank_improvement: stats1['league_rank'] - stats2['league_rank'] # Positive = better
    }
  end
  
  # Get current season identifier (e.g., "2024-2025")
  def current_season
    today = Date.today
    year = today.year
    month = today.month
    
    # NHL season typically runs from October to June
    # If we're in months 1-6, season started previous year
    # If we're in months 7-12, season starts this year
    if month >= 7
      "#{year}-#{year + 1}"
    else
      "#{year - 1}-#{year}"
    end
  end
  
  private
  
  def ensure_data_file_exists
    return if File.exist?(@data_file)
    
    FileUtils.mkdir_p(File.dirname(@data_file))
    save_data({})
  end
end
