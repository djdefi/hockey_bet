begin
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
    add_group 'Core', 'lib'
  end
rescue LoadError
  # SimpleCov not available, skip coverage reporting
end

require 'bigdecimal' # Ensure bigdecimal is loaded for dependencies like multi_xml

# Load our production code before tests to avoid multiple definitions
require_relative '../lib/standings_processor'

# Create a module with the helper methods
module StandingsHelpers
  def find_next_games(teams, schedule)
    @processor ||= StandingsProcessor.new
    @processor.send(:find_next_games, teams, schedule)
  end

  def check_fan_team_opponent(next_games, manager_team_map)
    @processor ||= StandingsProcessor.new
    @processor.send(:check_fan_team_opponent, next_games, manager_team_map)
  end

  def get_opponent_name(game, team_id)
    @processor ||= StandingsProcessor.new
    @processor.send(:get_opponent_name, game, team_id)
  end

  def format_game_time(time)
    @processor ||= StandingsProcessor.new
    @processor.send(:format_game_time, time)
  end

  def convert_utc_to_pacific(utc_time_str)
    @processor ||= StandingsProcessor.new
    @processor.send(:convert_utc_to_pacific, utc_time_str)
  end
end

# See https://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  # Include the helpers in all test contexts
  config.include StandingsHelpers
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Include StandingsProcessor methods globally for tests
  config.include Module.new {
    def find_next_games(teams, schedule)
      StandingsProcessor.new.send(:find_next_games, teams, schedule)
    end

    def check_fan_team_opponent(next_games, manager_team_map)
      StandingsProcessor.new.send(:check_fan_team_opponent, next_games, manager_team_map)
    end

    def get_opponent_name(game, team_id)
      StandingsProcessor.new.send(:get_opponent_name, game, team_id)
    end

    def format_game_time(time)
      StandingsProcessor.new.send(:format_game_time, time)
    end

    def convert_utc_to_pacific(utc_time_str)
      StandingsProcessor.new.send(:convert_utc_to_pacific, utc_time_str)
    end
  }

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.order = :random
  Kernel.srand config.seed
end
