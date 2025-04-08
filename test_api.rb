#!/usr/bin/env ruby
require 'httparty'
require 'json'
require_relative 'lib/api_validator'
require_relative 'lib/playoff_processor'

puts "Script starting..."
puts "Ruby version: #{RUBY_VERSION}"

class ApiTester
  def initialize
    @validator = ApiValidator.new
    puts "Testing NHL API endpoints..."
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
    print "Testing standings API... "
    url = "https://api-web.nhle.com/v1/standings/now"
    response = HTTParty.get(url)

    if response.code == 200
      data = JSON.parse(response.body)
      if @validator.validate_teams_response(data)
        puts "✅ SUCCESS"
        return true
      else
        puts "❌ FAILED (invalid schema)"
        return false
      end
    else
      puts "❌ FAILED (status code: #{response.code})"
      return false
    end
  end

  def test_schedule
    print "Testing schedule API... "
    url = "https://api-web.nhle.com/v1/schedule/now"
    response = HTTParty.get(url)

    if response.code == 200
      data = JSON.parse(response.body)
      if @validator.validate_schedule_response(data)
        puts "✅ SUCCESS"
        return true
      else
        puts "❌ FAILED (invalid schema)"
        return false
      end
    else
      puts "❌ FAILED (status code: #{response.code})"
      return false
    end
  end

  def test_playoffs
    # Test both playoff endpoints
    test_playoffs_now
    test_playoffs_standings
  end

  def test_playoffs_now
    print "Testing playoffs/now API... "
    url = "https://api-web.nhle.com/v1/playoffs/now"
    response = HTTParty.get(url)

    if response.code == 200
      data = JSON.parse(response.body)
      if @validator.validate_playoffs_response(data)
        puts "✅ SUCCESS"
        return true
      else
        puts "❌ FAILED (invalid schema)"
        puts "Response keys: #{data.keys.join(', ')}"
        return false
      end
    else
      puts "❌ FAILED (status code: #{response.code})"
      return false
    end
  end

  def test_playoffs_standings
    print "Testing standings/playoffs API... "
    url = "https://api-web.nhle.com/v1/standings/playoffs"
    response = HTTParty.get(url)

    if response.code == 200
      data = JSON.parse(response.body)
      if @validator.validate_playoffs_response(data)
        puts "✅ SUCCESS"
        return true
      else
        puts "❌ FAILED (invalid schema)"
        puts "Response keys: #{data.keys.join(', ')}"
        return false
      end
    else
      puts "❌ FAILED (status code: #{response.code})"
      return false
    end
  end

  def test_playoff_processor
    print "Testing PlayoffProcessor... "
    begin
      processor = PlayoffProcessor.new
      result = processor.fetch_playoff_data
      if result
        puts "✅ SUCCESS (data loaded successfully)"
        puts "  Playoff rounds: #{processor.playoff_rounds.size}"
        puts "  Teams with cup odds: #{processor.cup_odds.size}"
      else
        puts "⚠️ WARNING (no playoff data available, but no errors)"
      end
    rescue => e
      puts "❌ FAILED"
      puts "  Error: #{e.message}"
      puts "  #{e.backtrace.first(3).join("\n  ")}"
    end
  end
end

# Run the tests
tester = ApiTester.new
tester.test_all
