#!/usr/bin/env ruby
# Simple test for NHL playoffs API
require 'httparty'
require 'json'

output = []
output << "==== Testing NHL Playoffs API ===="
output << "Ruby version: #{RUBY_VERSION}"
output << "Time: #{Time.now}"

# Test playoffs/now endpoint
output << "\nTesting https://api-web.nhle.com/v1/playoffs/now..."
begin
  response = HTTParty.get("https://api-web.nhle.com/v1/playoffs/now")
  output << "Status code: #{response.code}"
  if response.code == 200
    data = JSON.parse(response.body)
    output << "Response keys: #{data.keys.join(', ')}"
    output << "API works correctly!"
  else
    output << "Failed to access the endpoint with status code: #{response.code}"
  end
rescue => e
  output << "Error: #{e.message}"
end

# Test standings/playoffs endpoint
output << "\nTesting https://api-web.nhle.com/v1/standings/playoffs..."
begin
  response = HTTParty.get("https://api-web.nhle.com/v1/standings/playoffs")
  output << "Status code: #{response.code}"
  if response.code == 200
    data = JSON.parse(response.body)
    output << "Response keys: #{data.keys.join(', ')}"
    output << "API works correctly!"
  else
    output << "Failed to access the endpoint with status code: #{response.code}"
  end
rescue => e
  output << "Error: #{e.message}"
end

output << "\n==== Test complete ===="

# Write results to file
File.write('api_test_results.txt', output.join("\n"))
puts "Test completed - see api_test_results.txt for results"
