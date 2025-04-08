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
    check_playoffs_api

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

  def check_playoffs_api
    # Try both playoff endpoints
    playoffs_now_url = "https://api-web.nhle.com/v1/playoffs/now"
    playoffs_standings_url = "https://api-web.nhle.com/v1/standings/playoffs"

    # Try the playoffs/now endpoint first
    now_response = HTTParty.get(playoffs_now_url)

    if now_response.code == 200
      data = JSON.parse(now_response.body)
      if @validator.validate_playoffs_response(data)
        puts "✅ Playoffs/now API validation passed"
        return
      end
    end

    # Fall back to the standings/playoffs endpoint
    standings_response = HTTParty.get(playoffs_standings_url)

    if standings_response.code == 200
      data = JSON.parse(standings_response.body)
      if @validator.validate_playoffs_response(data)
        puts "✅ Standings/playoffs API validation passed"
        return
      end
    end

    # If we're here, neither endpoint worked as expected
    if now_response.code != 200 && standings_response.code != 200
      raise "❌ Both playoffs APIs returned non-200 status codes: #{now_response.code}, #{standings_response.code}"
    else
      raise "❌ Playoffs API schema has changed!"
    end
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
