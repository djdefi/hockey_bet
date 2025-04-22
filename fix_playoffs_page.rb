#!/usr/bin/env ruby
require_relative 'lib/playoff_processor'

# Create processor and generate the playoffs page with corrected data format
processor = PlayoffProcessor.new
output_path = '_site/playoffs.html'

# Add adapter method to convert top_seed/bottom_seed format to home_team/away_team format
def adapt_playoff_data(processor)
  # Don't change if there are no playoff rounds
  return if processor.playoff_rounds.empty?

  # Create adapter for each round
  processor.playoff_rounds.each do |round|
    round[:series].each do |series|
      # Map from top_seed/bottom_seed to home_team/away_team format
      if series.key?(:top_seed) && series.key?(:bottom_seed)
        series[:home_team] = series[:top_seed]
        series[:away_team] = series[:bottom_seed]

        # Map wins to home_wins/away_wins format
        series[:home_wins] = series[:top_seed][:wins] || 0
        series[:away_wins] = series[:bottom_seed][:wins] || 0

        # Make these always be integers
        series[:home_wins] = series[:home_wins].to_i
        series[:away_wins] = series[:away_wins].to_i
      end
    end
  end
end

# Fetch playoff data
processor.fetch_playoff_data

# Adapt data to match template expectations
adapt_playoff_data(processor)

# Process and generate the playoffs HTML
processor.process(output_path)

puts "Playoffs page generated with adapted data format!"
