#!/usr/bin/env ruby
# filepath: /workspaces/hockey_bet/update_standings.rb

require_relative 'lib/standings_processor'

begin
  # Create the standings processor with default settings
  processor = StandingsProcessor.new
  
  # Process and output the standings page
  processor.process('fan_team.csv', '_site/index.html')
  
  puts "NHL standings updated successfully!"
rescue => e
  puts "Error updating NHL standings: #{e.message}"
  puts e.backtrace
  exit 1
end
