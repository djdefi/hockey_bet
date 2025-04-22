require 'spec_helper'
require 'httparty'
require_relative '../lib/api_validator'

# These tests make actual API calls and should be tagged to allow skipping them
RSpec.describe 'NHL API Integration', :api_integration do
  let(:logger) { instance_double(Logger, error: nil, debug: nil, warn: nil) }
  let(:validator) { ApiValidator.new(logger) }

  describe 'NHL API endpoints' do
    it 'returns valid data from standings API' do
      url = 'https://api-web.nhle.com/v1/standings/now'
      response = HTTParty.get(url)

      expect(response.code).to eq(200)
      expect(validator.validate_teams_response(JSON.parse(response.body))).to be true
    end

    it 'returns valid data from schedule API' do
      url = 'https://api-web.nhle.com/v1/schedule/now'
      response = HTTParty.get(url)

      expect(response.code).to eq(200)
      expect(validator.validate_schedule_response(JSON.parse(response.body))).to be true
    end

    it 'returns valid data from playoff-bracket API' do
      url = 'https://api-web.nhle.com/v1/playoff-bracket/2025'
      response = HTTParty.get(url)

      expect(response.code).to eq(200)
      expect(validator.validate_playoffs_response(JSON.parse(response.body))).to be true
    end

    it 'returns valid data from playoff-series/carousel API' do
      url = 'https://api-web.nhle.com/v1/playoff-series/carousel/20242025/'
      response = HTTParty.get(url)

      expect(response.code).to eq(200)
      expect(validator.validate_playoffs_response(JSON.parse(response.body))).to be true
    end

    it 'returns valid data from schedule/playoff-series API' do
      url = 'https://api-web.nhle.com/v1/schedule/playoff-series/20242025/a'
      response = HTTParty.get(url)

      expect(response.code).to eq(200)
      expect(validator.validate_playoffs_response(JSON.parse(response.body))).to be true
    end
  end
end
