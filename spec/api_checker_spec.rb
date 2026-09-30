require 'spec_helper'
require_relative '../.github/scripts/check_api'

RSpec.describe ApiChecker do
  let(:checker) { described_class.new }
  let(:bracket_url) { 'https://api-web.nhle.com/v1/playoff-bracket/2027' }

  before do
    allow(Date).to receive(:today).and_return(Date.new(2026, 9, 30))
    allow(HTTParty).to receive(:get).with('https://api-web.nhle.com/v1/standings/now')
      .and_return(double(code: 200, body: File.read('spec/fixtures/teams.json')))
    allow(HTTParty).to receive(:get).with('https://api-web.nhle.com/v1/schedule/now')
      .and_return(double(code: 200, body: File.read('spec/fixtures/schedule.json')))
  end

  it 'accepts an empty current bracket before playoffs without calling retired endpoints' do
    expect(HTTParty).to receive(:get).with(bracket_url)
      .and_return(double(code: 200, body: '{"series":[]}'))
    expect { checker.check_apis }.to output(/All API validations passed/).to_stdout
  end

  it 'accepts an active bracket in the spring' do
    allow(Date).to receive(:today).and_return(Date.new(2027, 4, 20))
    expect(HTTParty).to receive(:get).with(bracket_url)
      .and_return(double(code: 200, body: '{"series":[{"playoffRound":1}]}'))
    expect { checker.check_apis }.not_to raise_error
  end

  it 'fails on HTTP errors instead of accepting fallback playoff data' do
    allow(HTTParty).to receive(:get).with(bracket_url)
      .and_return(double(code: 503, body: 'Unavailable'))
    expect { checker.check_apis }.to raise_error(/status code 503/)
  end

  it 'fails on malformed bracket data' do
    allow(HTTParty).to receive(:get).with(bracket_url)
      .and_return(double(code: 200, body: '{"series":[{}]}'))
    expect { checker.check_apis }.to raise_error(/schema has changed/)
  end
end
