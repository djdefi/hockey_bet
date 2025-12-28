require 'date'

# Validation utility methods for common validation patterns
# Provides reusable validation logic across the application
module ValidationUtils
  # Validation error class for better error handling
  class ValidationError < StandardError
    attr_reader :field, :value, :constraint
    
    def initialize(field, value, constraint, message = nil)
      @field = field
      @value = value
      @constraint = constraint
      super(message || "Validation failed for #{field}: #{constraint}")
    end
  end
  
  # Validate that a value is not nil or empty
  # @param value [Object] Value to validate
  # @param field_name [String] Field name for error message
  # @raise [ValidationError] if value is nil or empty
  # @return [Object] The validated value
  def validate_presence(value, field_name)
    if value.nil? || (value.respond_to?(:empty?) && value.empty?) || (value.is_a?(String) && value.strip.empty?)
      raise ValidationError.new(field_name, value, "must be present")
    end
    value
  end
  
  # Validate that a value is one of the allowed values
  # @param value [Object] Value to validate
  # @param field_name [String] Field name for error message
  # @param allowed_values [Array] Array of allowed values
  # @raise [ValidationError] if value is not in allowed_values
  # @return [Object] The validated value
  def validate_inclusion(value, field_name, allowed_values)
    unless allowed_values.include?(value)
      raise ValidationError.new(
        field_name,
        value,
        "must be one of: #{allowed_values.join(', ')}"
      )
    end
    value
  end
  
  # Validate that a numeric value is within a range
  # @param value [Numeric] Value to validate
  # @param field_name [String] Field name for error message
  # @param min [Numeric, nil] Minimum value (nil for no minimum)
  # @param max [Numeric, nil] Maximum value (nil for no maximum)
  # @raise [ValidationError] if value is out of range
  # @return [Numeric] The validated value
  def validate_range(value, field_name, min: nil, max: nil)
    unless value.is_a?(Numeric)
      raise ValidationError.new(field_name, value, "must be a number")
    end
    
    if min && value < min
      raise ValidationError.new(field_name, value, "must be >= #{min}")
    end
    
    if max && value > max
      raise ValidationError.new(field_name, value, "must be <= #{max}")
    end
    
    value
  end
  
  # Validate that a string matches a pattern
  # @param value [String] Value to validate
  # @param field_name [String] Field name for error message
  # @param pattern [Regexp] Regular expression pattern
  # @raise [ValidationError] if value doesn't match pattern
  # @return [String] The validated value
  def validate_format(value, field_name, pattern)
    unless value.is_a?(String) && value.match?(pattern)
      raise ValidationError.new(
        field_name,
        value,
        "must match pattern: #{pattern.inspect}"
      )
    end
    value
  end
  
  # Validate that a value is a valid date
  # @param value [String, Date] Value to validate
  # @param field_name [String] Field name for error message
  # @raise [ValidationError] if value is not a valid date
  # @return [Date] The parsed date
  def validate_date(value, field_name)
    return value if value.is_a?(Date)
    
    Date.parse(value.to_s)
  rescue ArgumentError
    raise ValidationError.new(field_name, value, "must be a valid date")
  end
  
  # Validate that a hash contains required keys
  # @param hash [Hash] Hash to validate
  # @param required_keys [Array] Array of required key names
  # @param field_name [String] Field name for error message
  # @raise [ValidationError] if required keys are missing
  # @return [Hash] The validated hash
  def validate_hash_keys(hash, required_keys, field_name = "hash")
    unless hash.is_a?(Hash)
      raise ValidationError.new(field_name, hash, "must be a Hash")
    end
    
    missing_keys = required_keys - hash.keys
    unless missing_keys.empty?
      raise ValidationError.new(
        field_name,
        hash,
        "missing required keys: #{missing_keys.join(', ')}"
      )
    end
    
    hash
  end
  
  # Validate multiple conditions and collect all errors
  # @yield Block that performs validations
  # @return [Array<ValidationError>] Array of validation errors (empty if valid)
  def validate_all
    errors = []
    begin
      yield
    rescue ValidationError => e
      errors << e
    end
    errors
  end
  
  # Perform validation and return result with errors
  # @param value [Object] Value to validate
  # @yield [value] Block that performs validation and returns cleaned value
  # @return [Hash] Result with :valid, :value, and :errors keys
  def safe_validate(value)
    result = { valid: false, value: nil, errors: [] }
    
    begin
      result[:value] = yield(value)
      result[:valid] = true
    rescue ValidationError => e
      result[:errors] << e
    rescue StandardError => e
      result[:errors] << ValidationError.new('unknown', value, e.message)
    end
    
    result
  end
end
