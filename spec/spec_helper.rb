require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_group 'Core', 'lib'
end

require 'bigdecimal' # Ensure bigdecimal is loaded for dependencies like multi_xml
require_relative 'bigdecimal' # Explicitly load bigdecimal using require_relative

# Load our production code before tests to avoid multiple definitions
require_relative '../lib/standings_processor'

# See https://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

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
