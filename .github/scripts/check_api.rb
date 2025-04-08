#!/usr/bin/env ruby
# This script checks the NHL API for schema changes

require 'httparty'
require 'json'
require_relative '../../lib/api_validator'

class ApiChecker
  def initialize
    @validator = ApiValidator.new
  end
  
  def check_apis
    check_standings_api
    check_schedule_api
    
    puts "✅ All API validations passed!"
  end
  
  private
  
  def check_standings_api
    url = "https://api-web.nhle.com/v1/standings/now"
    response = HTTParty.get(url)
    
    if response.code != 200
      raise "❌ Standings API returned status code #{response.code}"
    end
    
    data = JSON.parse(response.body)
    unless @validator.validate_teams_response(data)
      raise "❌ Standings API schema has changed!"
    end
    
    puts "✅ Standings API validation passed"
  end
  
  def check_schedule_api
    url = "https://api-web.nhle.com/v1/schedule/now"
    response = HTTParty.get(url)
    
    if response.code != 200
      raise "❌ Schedule API returned status code #{response.code}"
    end
    
    data = JSON.parse(response.body)
    unless @validator.validate_schedule_response(data)
      raise "❌ Schedule API schema has changed!"
    end
    
    puts "✅ Schedule API validation passed"
  end
end

# Run the checks
begin
  checker = ApiChecker.new
  checker.check_apis
  exit 0
rescue => e
  puts e.message
  exit 1
end
