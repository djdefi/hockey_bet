#!/usr/bin/env ruby
# filepath: /workspaces/hockey_bet/update_standings.rb
# Main entry point script for updating NHL standings and playoffs data
# This script orchestrates the data fetching, processing, and HTML generation
# Can run in normal mode or PR preview mode for GitHub Actions deployments

require_relative 'lib/standings_processor'
require_relative 'lib/playoff_processor'
require 'fileutils'

begin
  # Determine if we're running in PR preview mode
  pr_preview = ENV['PR_PREVIEW'] == 'true'
  pr_number = ENV.fetch('PR_NUMBER', nil)

  # Set up output directory based on environment
  if pr_preview && pr_number
    puts "Running in PR preview mode for PR ##{pr_number}"
    # Create a temporary directory for PR preview
    output_dir = '_site/original'
  else
    output_dir = '_site'
  end
  FileUtils.mkdir_p(output_dir)
  puts "Output directory: #{output_dir}"

  # Create the standings processor with default settings
  puts "Initializing standings processor..."
  processor = StandingsProcessor.new

  # Process and output the standings page
  standings_path = "#{output_dir}/standings.html"
  index_path = "#{output_dir}/index.html"
  
  puts "Processing NHL standings data..."
  processor.process('fan_team.csv', index_path)

  # If index.html exists but standings.html doesn't, create a copy for compatibility
  if File.exist?(index_path) && !File.exist?(standings_path)
    FileUtils.cp(index_path, standings_path)
    puts "Created standings.html copy for compatibility"
  end

  # Generate playoffs page
  begin
    puts "Processing NHL playoffs data..."
    playoff_processor = PlayoffProcessor.new
    # Pass the manager team map for fan cup odds calculation
    playoff_processor.process("#{output_dir}/playoffs.html", processor.manager_team_map)
    puts "NHL playoffs updated successfully!"
  rescue StandardError => e
    puts "Warning: Error updating NHL playoffs (continuing anyway): #{e.message}"
    puts "Error details: #{e.backtrace.first(3).join("\n")}" if e.backtrace
  end

  puts "✓ NHL standings updated successfully!"
  puts "  - Standings page: #{index_path}"
  puts "  - Number of teams: #{processor.teams.length}"
  puts "  - Fan teams tracked: #{processor.manager_team_map.values.reject { |v| v == 'N/A' }.uniq.length}"
  
rescue StandardError => e
  puts "✗ Error updating NHL standings: #{e.message}"
  puts "Stack trace:"
  puts e.backtrace.first(5).map { |line| "  #{line}" }.join("\n")
  exit 1
end
