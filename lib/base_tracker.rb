# filepath: /home/runner/work/hockey_bet/hockey_bet/lib/base_tracker.rb
require 'json'
require 'fileutils'

# BaseTracker provides common functionality for tracker classes
# Implements shared patterns for:
# - JSON file operations
# - Logging control
# - Error handling
# - Data persistence
module BaseTracker
  attr_reader :data_file
  attr_accessor :verbose
  
  # Initialize tracker with file path and logging preferences
  # @param data_file [String] Path to JSON data file
  # @param verbose [Boolean] Enable verbose logging (default: true)
  # @param default_content [Object] Default content for new file (default: {})
  def initialize_tracker(data_file, verbose: true, default_content: {})
    @data_file = data_file
    @verbose = verbose
    ensure_data_file_exists(default_content)
  end
  
  # Load data from JSON file with error handling
  # @return [Object] Parsed JSON data (Hash or Array depending on file)
  def load_data_safe(default_value = {})
    return default_value unless File.exist?(@data_file)
    
    JSON.parse(File.read(@data_file))
  rescue JSON::ParserError => e
    log_warning("Error parsing #{File.basename(@data_file)}: #{e.message}")
    default_value
  end
  
  # Save data to JSON file with pretty formatting
  # @param data [Object] Data to save (must be JSON-serializable)
  def save_data_safe(data)
    FileUtils.mkdir_p(File.dirname(@data_file))
    File.write(@data_file, JSON.pretty_generate(data))
  rescue StandardError => e
    log_error("Error saving #{File.basename(@data_file)}: #{e.message}")
    raise
  end
  
  # Ensure data file exists with default content
  # @param default_content [Object] Default content for new file
  def ensure_data_file_exists(default_content = {})
    return if File.exist?(@data_file)
    
    FileUtils.mkdir_p(File.dirname(@data_file))
    save_data_safe(default_content)
  end
  
  # Validate that a string input is not empty
  # @param value [String] Value to validate
  # @param field_name [String] Name of field for error message
  # @raise [ArgumentError] if value is nil or empty
  def validate_not_empty!(value, field_name)
    if value.nil? || value.to_s.strip.empty?
      raise ArgumentError, "#{field_name} cannot be empty"
    end
  end
  
  # Logging helpers - respect verbose flag
  
  # Log informational message
  # @param message [String] Message to log
  def log_info(message)
    puts message if @verbose
  end
  
  # Log warning message
  # @param message [String] Warning message to log
  def log_warning(message)
    puts "Warning: #{message}" if @verbose
  end
  
  # Log error message (always shown, regardless of verbose flag)
  # @param message [String] Error message to log
  def log_error(message)
    warn "Error: #{message}"
  end
end
