#!/usr/bin/env ruby
require 'httparty'
require 'json'
require_relative 'lib/api_validator'
require_relative 'lib/playoff_processor'

puts 'Script starting...'
puts "Ruby version: #{RUBY_VERSION}"

class ApiTester
  def initialize
    @validator = ApiValidator.new
    puts 'Testing NHL API endpoints...'
  end

  def test_all
    test_standings
    test_schedule
    test_playoffs
    test_playoff_processor

    puts "\n✅ All tests completed!"
  end

  private

  def test_standings
    print 'Testing standings API... '
    url = 'https://api-web.nhle.com/v1/standings/now'
    response = HTTParty.get(url)

    if response.code == 200
      data = JSON.parse(response.body)
      if @validator.validate_teams_response(data)
        puts '✅ SUCCESS'
        true
      else
        puts '❌ FAILED (invalid schema)'
        false
      end
    else
      puts "❌ FAILED (status code: #{response.code})"
      false
    end
  end

  def test_schedule
    print 'Testing schedule API... '
    url = 'https://api-web.nhle.com/v1/schedule/now'
    response = HTTParty.get(url)

    if response.code == 200
      data = JSON.parse(response.body)
      if @validator.validate_schedule_response(data)
        puts '✅ SUCCESS'
        true
      else
        puts '❌ FAILED (invalid schema)'
        false
      end
    else
      puts "❌ FAILED (status code: #{response.code})"
      false
    end
  end

  def test_playoffs
    # Test the working playoff endpoints
    test_playoff_bracket
    test_playoff_series_carousel
    test_playoff_series
  end

  def test_playoff_bracket
    print 'Testing playoff-bracket API... '
    url = 'https://api-web.nhle.com/v1/playoff-bracket/2025'
    response = HTTParty.get(url)

    if response.code == 200
      data = JSON.parse(response.body)
      if @validator.validate_playoffs_response(data)
        puts '✅ SUCCESS'
        true
      else
        puts '❌ FAILED (invalid schema)'
        puts "Response keys: #{data.keys.join(', ')}"
        false
      end
    else
      puts "❌ FAILED (status code: #{response.code})"
      false
    end
  end

  def test_playoff_series_carousel
    print 'Testing playoff-series/carousel API... '
    url = 'https://api-web.nhle.com/v1/playoff-series/carousel/20242025/'
    response = HTTParty.get(url)

    if response.code == 200
      data = JSON.parse(response.body)
      if @validator.validate_playoffs_response(data)
        puts '✅ SUCCESS'
        true
      else
        puts '❌ FAILED (invalid schema)'
        puts "Response keys: #{data.keys.join(', ')}"
        false
      end
    else
      puts "❌ FAILED (status code: #{response.code})"
      false
    end
  end

  def test_playoff_series
    print 'Testing schedule/playoff-series API... '
    url = 'https://api-web.nhle.com/v1/schedule/playoff-series/20242025/a'
    response = HTTParty.get(url)

    if response.code == 200
      data = JSON.parse(response.body)
      if @validator.validate_playoffs_response(data)
        puts '✅ SUCCESS'
        true
      else
        puts '❌ FAILED (invalid schema)'
        puts "Response keys: #{data.keys.join(', ')}"
        false
      end
    else
      puts "❌ FAILED (status code: #{response.code})"
      false
    end
  end

  def test_playoff_processor
    print 'Testing PlayoffProcessor... '
    begin
      processor = PlayoffProcessor.new
      result = processor.fetch_playoff_data
      if result
        puts '✅ SUCCESS (data loaded successfully)'
        puts "  Playoff rounds: #{processor.playoff_rounds.size}"
        puts "  Teams with cup odds: #{processor.cup_odds.size}"
      else
        puts '⚠️ WARNING (no playoff data available, but no errors)'
      end
    rescue StandardError => e
      puts '❌ FAILED'
      puts "  Error: #{e.message}"
      puts "  #{e.backtrace.first(3).join("\n  ")}"
    end
  end
end

# Run the tests
tester = ApiTester.new
tester.test_all
