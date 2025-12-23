require 'spec_helper'
require_relative '../lib/validation_utils'
require 'date'

RSpec.describe ValidationUtils do
  # Test class that includes ValidationUtils
  class TestValidator
    include ValidationUtils
    
    def validate_user_input(name, age, email, role)
      validate_presence(name, "Name")
      validate_range(age, "Age", min: 0, max: 120)
      validate_format(email, "Email", /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i)
      validate_inclusion(role, "Role", ['admin', 'user', 'guest'])
    end
  end
  
  let(:validator) { TestValidator.new }
  
  describe ValidationUtils::ValidationError do
    it 'creates error with field, value, and constraint' do
      error = ValidationUtils::ValidationError.new('email', 'invalid', 'must be valid format')
      
      expect(error.field).to eq('email')
      expect(error.value).to eq('invalid')
      expect(error.constraint).to eq('must be valid format')
      expect(error.message).to include('email')
    end
    
    it 'accepts custom message' do
      error = ValidationUtils::ValidationError.new('field', 'value', 'constraint', 'Custom message')
      expect(error.message).to eq('Custom message')
    end
  end
  
  describe '#validate_presence' do
    it 'passes for non-nil, non-empty values' do
      expect(validator.validate_presence("value", "Field")).to eq("value")
      expect(validator.validate_presence([1, 2], "Field")).to eq([1, 2])
      expect(validator.validate_presence({a: 1}, "Field")).to eq({a: 1})
    end
    
    it 'raises ValidationError for nil' do
      expect do
        validator.validate_presence(nil, "Name")
      end.to raise_error(ValidationUtils::ValidationError) do |error|
        expect(error.field).to eq("Name")
        expect(error.value).to be_nil
      end
    end
    
    it 'raises ValidationError for empty string' do
      expect do
        validator.validate_presence("", "Name")
      end.to raise_error(ValidationUtils::ValidationError)
    end
    
    it 'raises ValidationError for empty array' do
      expect do
        validator.validate_presence([], "Items")
      end.to raise_error(ValidationUtils::ValidationError)
    end
    
    it 'raises ValidationError for whitespace-only string' do
      expect do
        validator.validate_presence("   ", "Name")
      end.to raise_error(ValidationUtils::ValidationError)
    end
  end
  
  describe '#validate_inclusion' do
    it 'passes when value is in allowed list' do
      result = validator.validate_inclusion('admin', "Role", ['admin', 'user'])
      expect(result).to eq('admin')
    end
    
    it 'raises ValidationError when value is not in allowed list' do
      expect do
        validator.validate_inclusion('superadmin', "Role", ['admin', 'user'])
      end.to raise_error(ValidationUtils::ValidationError) do |error|
        expect(error.field).to eq("Role")
        expect(error.value).to eq('superadmin')
        expect(error.constraint).to include('admin')
        expect(error.constraint).to include('user')
      end
    end
    
    it 'works with numeric values' do
      result = validator.validate_inclusion(2, "Status", [1, 2, 3])
      expect(result).to eq(2)
    end
  end
  
  describe '#validate_range' do
    it 'passes for value within range' do
      expect(validator.validate_range(50, "Age", min: 0, max: 100)).to eq(50)
    end
    
    it 'passes for value at minimum boundary' do
      expect(validator.validate_range(0, "Age", min: 0, max: 100)).to eq(0)
    end
    
    it 'passes for value at maximum boundary' do
      expect(validator.validate_range(100, "Age", min: 0, max: 100)).to eq(100)
    end
    
    it 'passes with only minimum constraint' do
      expect(validator.validate_range(50, "Value", min: 0)).to eq(50)
    end
    
    it 'passes with only maximum constraint' do
      expect(validator.validate_range(50, "Value", max: 100)).to eq(50)
    end
    
    it 'raises ValidationError for non-numeric value' do
      expect do
        validator.validate_range("fifty", "Age", min: 0, max: 100)
      end.to raise_error(ValidationUtils::ValidationError) do |error|
        expect(error.constraint).to include('must be a number')
      end
    end
    
    it 'raises ValidationError for value below minimum' do
      expect do
        validator.validate_range(-5, "Age", min: 0, max: 100)
      end.to raise_error(ValidationUtils::ValidationError) do |error|
        expect(error.constraint).to include('>= 0')
      end
    end
    
    it 'raises ValidationError for value above maximum' do
      expect do
        validator.validate_range(150, "Age", min: 0, max: 100)
      end.to raise_error(ValidationUtils::ValidationError) do |error|
        expect(error.constraint).to include('<= 100')
      end
    end
  end
  
  describe '#validate_format' do
    it 'passes for matching pattern' do
      result = validator.validate_format('test@example.com', "Email", /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i)
      expect(result).to eq('test@example.com')
    end
    
    it 'raises ValidationError for non-matching pattern' do
      expect do
        validator.validate_format('invalid-email', "Email", /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i)
      end.to raise_error(ValidationUtils::ValidationError) do |error|
        expect(error.field).to eq("Email")
        expect(error.value).to eq('invalid-email')
      end
    end
    
    it 'raises ValidationError for non-string value' do
      expect do
        validator.validate_format(12345, "Email", /@/)
      end.to raise_error(ValidationUtils::ValidationError)
    end
  end
  
  describe '#validate_date' do
    it 'passes and returns Date object for valid date string' do
      result = validator.validate_date('2024-12-25', "Date")
      expect(result).to be_a(Date)
      expect(result).to eq(Date.new(2024, 12, 25))
    end
    
    it 'passes and returns Date object for Date input' do
      date = Date.today
      result = validator.validate_date(date, "Date")
      expect(result).to eq(date)
    end
    
    it 'raises ValidationError for invalid date string' do
      expect do
        validator.validate_date('not-a-date', "Date")
      end.to raise_error(ValidationUtils::ValidationError) do |error|
        expect(error.field).to eq("Date")
        expect(error.constraint).to include('must be a valid date')
      end
    end
    
    it 'raises ValidationError for invalid date format' do
      expect do
        validator.validate_date('2024-13-45', "Date")
      end.to raise_error(ValidationUtils::ValidationError)
    end
  end
  
  describe '#validate_hash_keys' do
    it 'passes for hash with all required keys' do
      hash = {name: 'John', age: 30, email: 'john@example.com'}
      result = validator.validate_hash_keys(hash, [:name, :age], "User")
      expect(result).to eq(hash)
    end
    
    it 'raises ValidationError for non-hash value' do
      expect do
        validator.validate_hash_keys("not a hash", [:name], "User")
      end.to raise_error(ValidationUtils::ValidationError) do |error|
        expect(error.constraint).to include('must be a Hash')
      end
    end
    
    it 'raises ValidationError for missing required keys' do
      hash = {name: 'John'}
      expect do
        validator.validate_hash_keys(hash, [:name, :age, :email], "User")
      end.to raise_error(ValidationUtils::ValidationError) do |error|
        expect(error.constraint).to include('missing required keys')
        expect(error.constraint).to include('age')
        expect(error.constraint).to include('email')
      end
    end
    
    it 'allows extra keys not in required list' do
      hash = {name: 'John', age: 30, extra: 'data'}
      result = validator.validate_hash_keys(hash, [:name, :age], "User")
      expect(result).to eq(hash)
    end
  end
  
  describe '#safe_validate' do
    it 'returns valid result for successful validation' do
      result = validator.safe_validate("test@example.com") do |value|
        validator.validate_format(value, "Email", /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i)
      end
      
      expect(result[:valid]).to be true
      expect(result[:value]).to eq("test@example.com")
      expect(result[:errors]).to be_empty
    end
    
    it 'returns invalid result with errors for failed validation' do
      result = validator.safe_validate("invalid-email") do |value|
        validator.validate_format(value, "Email", /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i)
      end
      
      expect(result[:valid]).to be false
      expect(result[:value]).to be_nil
      expect(result[:errors]).not_to be_empty
      expect(result[:errors].first).to be_a(ValidationUtils::ValidationError)
    end
    
    it 'captures standard errors and wraps them' do
      result = validator.safe_validate("value") do |value|
        raise StandardError, "Something went wrong"
      end
      
      expect(result[:valid]).to be false
      expect(result[:errors]).not_to be_empty
      expect(result[:errors].first).to be_a(ValidationUtils::ValidationError)
    end
  end
  
  describe 'integration test with multiple validations' do
    it 'validates valid user input' do
      expect do
        validator.validate_user_input('John Doe', 30, 'john@example.com', 'admin')
      end.not_to raise_error
    end
    
    it 'raises ValidationError for invalid name' do
      expect do
        validator.validate_user_input('', 30, 'john@example.com', 'admin')
      end.to raise_error(ValidationUtils::ValidationError) do |error|
        expect(error.field).to eq('Name')
      end
    end
    
    it 'raises ValidationError for invalid age' do
      expect do
        validator.validate_user_input('John', 150, 'john@example.com', 'admin')
      end.to raise_error(ValidationUtils::ValidationError) do |error|
        expect(error.field).to eq('Age')
      end
    end
    
    it 'raises ValidationError for invalid email' do
      expect do
        validator.validate_user_input('John', 30, 'not-an-email', 'admin')
      end.to raise_error(ValidationUtils::ValidationError) do |error|
        expect(error.field).to eq('Email')
      end
    end
    
    it 'raises ValidationError for invalid role' do
      expect do
        validator.validate_user_input('John', 30, 'john@example.com', 'superadmin')
      end.to raise_error(ValidationUtils::ValidationError) do |error|
        expect(error.field).to eq('Role')
      end
    end
  end
end
