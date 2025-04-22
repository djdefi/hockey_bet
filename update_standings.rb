#!/usr/bin/env ruby
# filepath: /workspaces/hockey_bet/update_standings.rb

require_relative 'lib/standings_processor'
require_relative 'lib/playoff_processor'

begin
  # Determine if we're running in PR preview mode
  pr_preview = ENV['PR_PREVIEW'] == 'true'
  pr_number = ENV['PR_NUMBER']

  # Set up output directory based on environment
  if pr_preview && pr_number
    puts "Running in PR preview mode for PR ##{pr_number}"
    # Create a temporary directory for PR preview
    output_dir = '_site/original'
    Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  else
    output_dir = '_site'
    Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  end

  # Create the standings processor with default settings
  processor = StandingsProcessor.new

  # Process and output the standings page
  standings_path = "#{output_dir}/standings.html"
  index_path = "#{output_dir}/index.html"
  processor.process('fan_team.csv', index_path)

  # If index.html exists but standings.html doesn't, create a copy
  if File.exist?(index_path) && !File.exist?(standings_path)
    FileUtils.cp(index_path, standings_path)
  end

  # Generate playoffs page
  begin
    playoff_processor = PlayoffProcessor.new
    playoff_processor.process("#{output_dir}/playoffs.html")
    puts "NHL playoffs updated successfully!"
  rescue => e
    puts "Warning: Error updating NHL playoffs (continuing anyway): #{e.message}"
  end

  puts "NHL standings updated successfully!"
rescue => e
  puts "Error updating NHL standings: #{e.message}"
  puts e.backtrace
  exit 1
end
