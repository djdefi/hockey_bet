# filepath: /home/runner/work/hockey_bet/hockey_bet/spec/fan_league_constants_spec.rb

require_relative '../lib/fan_league_constants'
require 'date'

RSpec.describe FanLeagueConstants do
  describe 'FAN_NAMES' do
    it 'contains exactly 13 fan names' do
      expect(FanLeagueConstants::FAN_NAMES.size).to eq(13)
    end
    
    it 'is frozen to prevent modification' do
      expect(FanLeagueConstants::FAN_NAMES).to be_frozen
    end
    
    it 'contains expected fan names' do
      expect(FanLeagueConstants::FAN_NAMES).to include('Jeff C.')
      expect(FanLeagueConstants::FAN_NAMES).to include('Brian D.')
      expect(FanLeagueConstants::FAN_NAMES).to include('Ryan T.')
    end
  end
  
  describe '.valid_fan_name?' do
    it 'returns true for valid fan names' do
      expect(FanLeagueConstants.valid_fan_name?('Jeff C.')).to be true
      expect(FanLeagueConstants.valid_fan_name?('Brian D.')).to be true
    end
    
    it 'returns false for invalid fan names' do
      expect(FanLeagueConstants.valid_fan_name?('John Doe')).to be false
      expect(FanLeagueConstants.valid_fan_name?('')).to be false
      expect(FanLeagueConstants.valid_fan_name?(nil)).to be false
    end
  end
  
  describe '.current_season' do
    it 'returns correct season for fall months' do
      date = Date.new(2024, 10, 15)
      expect(FanLeagueConstants.current_season(date)).to eq('2024-2025')
    end
    
    it 'returns correct season for winter months' do
      date = Date.new(2025, 1, 15)
      expect(FanLeagueConstants.current_season(date)).to eq('2024-2025')
    end
    
    it 'returns correct season for summer months' do
      date = Date.new(2024, 8, 15)
      expect(FanLeagueConstants.current_season(date)).to eq('2024-2025')
    end
    
    it 'uses today by default' do
      season = FanLeagueConstants.current_season
      expect(season).to match(/\d{4}-\d{4}/)
    end
  end
  
  describe 'file path constants' do
    it 'defines predictions file path' do
      expect(FanLeagueConstants::PREDICTIONS_FILE).to eq('data/predictions.json')
    end
    
    it 'defines prediction results file path' do
      expect(FanLeagueConstants::PREDICTION_RESULTS_FILE).to eq('data/prediction_results.json')
    end
    
    it 'defines standings history file path' do
      expect(FanLeagueConstants::STANDINGS_HISTORY_FILE).to eq('data/standings_history.json')
    end
  end
end
