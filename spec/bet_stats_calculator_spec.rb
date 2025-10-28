# filepath: /home/runner/work/hockey_bet/hockey_bet/spec/bet_stats_calculator_spec.rb
require_relative '../lib/bet_stats_calculator'
require 'json'

RSpec.describe BetStatsCalculator do
  let(:teams) do
    JSON.parse(File.read('spec/fixtures/teams.json'))['standings']
  end

  let(:manager_team_map) do
    {
      'BOS' => 'Alice',
      'FLA' => 'Bob',
      'TOR' => 'Charlie',
      'TBL' => 'N/A',
      'DET' => 'Diana',
      'OTT' => 'N/A'
    }
  end

  let(:next_games) do
    {
      'BOS' => {
        'startTimeUTC' => '2025-04-09T23:00:00Z',
        'awayTeam' => { 'abbrev' => 'FLA', 'placeName' => { 'default' => 'Florida' } },
        'homeTeam' => { 'abbrev' => 'BOS', 'placeName' => { 'default' => 'Boston' } },
        'isFanTeamOpponent' => true
      },
      'FLA' => {
        'startTimeUTC' => '2025-04-09T23:00:00Z',
        'awayTeam' => { 'abbrev' => 'FLA', 'placeName' => { 'default' => 'Florida' } },
        'homeTeam' => { 'abbrev' => 'BOS', 'placeName' => { 'default' => 'Boston' } },
        'isFanTeamOpponent' => true
      },
      'TOR' => {
        'startTimeUTC' => '2025-04-10T23:00:00Z',
        'awayTeam' => { 'abbrev' => 'TOR', 'placeName' => { 'default' => 'Toronto' } },
        'homeTeam' => { 'abbrev' => 'DET', 'placeName' => { 'default' => 'Detroit' } },
        'isFanTeamOpponent' => true
      },
      'DET' => {
        'startTimeUTC' => '2025-04-10T23:00:00Z',
        'awayTeam' => { 'abbrev' => 'TOR', 'placeName' => { 'default' => 'Toronto' } },
        'homeTeam' => { 'abbrev' => 'DET', 'placeName' => { 'default' => 'Detroit' } },
        'isFanTeamOpponent' => true
      },
      'TBL' => {
        'startTimeUTC' => 'None',
        'awayTeam' => { 'abbrev' => 'None', 'placeName' => { 'default' => 'None' } },
        'homeTeam' => { 'abbrev' => 'None', 'placeName' => { 'default' => 'None' } },
        'isFanTeamOpponent' => false
      },
      'OTT' => {
        'startTimeUTC' => 'None',
        'awayTeam' => { 'abbrev' => 'None', 'placeName' => { 'default' => 'None' } },
        'homeTeam' => { 'abbrev' => 'None', 'placeName' => { 'default' => 'None' } },
        'isFanTeamOpponent' => false
      }
    }
  end

  let(:calculator) { BetStatsCalculator.new(teams, manager_team_map, next_games) }

  describe '#initialize' do
    it 'initializes with teams, manager map, and next games' do
      expect(calculator.instance_variable_get(:@teams)).to eq(teams)
      expect(calculator.instance_variable_get(:@manager_team_map)).to eq(manager_team_map)
      expect(calculator.instance_variable_get(:@next_games)).to eq(next_games)
    end

    it 'initializes stats as empty hash' do
      expect(calculator.stats).to eq({})
    end
  end

  describe '#fan_teams' do
    it 'returns only teams owned by fans' do
      fan_teams = calculator.fan_teams
      fan_abbrevs = fan_teams.map { |t| t['teamAbbrev']['default'] }
      
      expect(fan_abbrevs).to include('BOS', 'FLA', 'TOR', 'DET')
      expect(fan_abbrevs).not_to include('TBL', 'OTT')
    end

    it 'excludes teams with N/A fan' do
      fan_teams = calculator.fan_teams
      fan_names = fan_teams.map { |t| manager_team_map[t['teamAbbrev']['default']] }
      
      expect(fan_names).not_to include('N/A')
    end
  end

  describe '#calculate_top_winners' do
    it 'returns top 3 fans with most wins' do
      top_winners = calculator.calculate_top_winners
      
      expect(top_winners.size).to be <= 3
      expect(top_winners.first[:fan]).to eq('Alice')
      expect(top_winners.first[:team]).to eq('Boston Bruins')
      expect(top_winners.first[:value]).to eq(50)
    end

    it 'sorts by wins in descending order' do
      top_winners = calculator.calculate_top_winners
      wins = top_winners.map { |w| w[:value] }
      
      expect(wins).to eq(wins.sort.reverse)
    end

    it 'includes display field' do
      top_winners = calculator.calculate_top_winners
      
      top_winners.each do |winner|
        expect(winner).to have_key(:display)
        expect(winner[:display]).to be_a(String)
      end
    end
  end

  describe '#calculate_top_losers' do
    it 'returns top 3 fans with most losses' do
      top_losers = calculator.calculate_top_losers
      
      expect(top_losers.size).to be <= 3
      expect(top_losers).to all(have_key(:fan))
      expect(top_losers).to all(have_key(:value))
    end

    it 'sorts by losses in descending order' do
      top_losers = calculator.calculate_top_losers
      losses = top_losers.map { |l| l[:value] }
      
      expect(losses).to eq(losses.sort.reverse)
    end
  end

  describe '#calculate_upcoming_fan_matchups' do
    it 'returns upcoming games between fan teams' do
      matchups = calculator.calculate_upcoming_fan_matchups
      
      expect(matchups).to be_an(Array)
      expect(matchups.size).to be <= 3
    end

    it 'includes matchup details' do
      matchups = calculator.calculate_upcoming_fan_matchups
      
      matchups.each do |matchup|
        expect(matchup).to have_key(:home_fan)
        expect(matchup).to have_key(:away_fan)
        expect(matchup).to have_key(:home_team)
        expect(matchup).to have_key(:away_team)
        expect(matchup).to have_key(:interest_score)
      end
    end

    it 'does not include duplicate matchups' do
      matchups = calculator.calculate_upcoming_fan_matchups
      
      # Create a set of unique matchup pairs
      pairs = matchups.map { |m| [m[:home_fan], m[:away_fan]].sort }
      
      expect(pairs.uniq.size).to eq(pairs.size)
    end

    it 'calculates interest score based on point differential' do
      matchups = calculator.calculate_upcoming_fan_matchups
      
      matchups.each do |matchup|
        expect(matchup[:interest_score]).to be_a(Numeric)
        # Interest score should be 100 - point differential
        expected_score = 100 - (matchup[:home_points] - matchup[:away_points]).abs
        expect(matchup[:interest_score]).to eq(expected_score)
      end
    end
  end

  describe '#calculate_longest_win_streak' do
    it 'returns the fan with longest winning streak' do
      longest = calculator.calculate_longest_win_streak
      
      if longest
        expect(longest).to have_key(:fan)
        expect(longest).to have_key(:value)
        expect(longest).to have_key(:display)
      end
    end

    it 'returns nil if no fan has a winning streak' do
      # Modify teams to have no winning streaks
      teams_no_wins = teams.map do |team|
        team.merge('streakCode' => 'L1')
      end
      
      calc = BetStatsCalculator.new(teams_no_wins, manager_team_map, next_games)
      expect(calc.calculate_longest_win_streak).to be_nil
    end

    it 'parses streak code correctly' do
      longest = calculator.calculate_longest_win_streak
      
      if longest
        expect(longest[:value]).to be_a(Integer)
        expect(longest[:value]).to be > 0
      end
    end
  end

  describe '#calculate_longest_lose_streak' do
    it 'returns the fan with longest losing streak' do
      longest = calculator.calculate_longest_lose_streak
      
      if longest
        expect(longest).to have_key(:fan)
        expect(longest).to have_key(:value)
        expect(longest).to have_key(:display)
      end
    end

    it 'only considers teams with losing streaks' do
      # If there's a longest losing streak, it should start with L
      longest = calculator.calculate_longest_lose_streak
      
      if longest
        expect(longest[:display]).to match(/^L\d+/)
      end
    end
  end

  describe '#calculate_best_point_differential' do
    it 'returns the fan with best goal differential' do
      best = calculator.calculate_best_point_differential
      
      if best
        expect(best).to have_key(:fan)
        expect(best).to have_key(:value)
        expect(best[:value]).to be_a(Numeric)
      end
    end

    it 'includes goals suffix in display' do
      best = calculator.calculate_best_point_differential
      
      if best
        expect(best[:display]).to include('goals')
      end
    end
  end

  describe '#calculate_most_dominant' do
    it 'returns the fan with best win percentage' do
      dominant = calculator.calculate_most_dominant
      
      expect(dominant).to have_key(:fan)
      expect(dominant).to have_key(:value)
      expect(dominant[:value]).to be_a(Numeric)
    end

    it 'displays win percentage' do
      dominant = calculator.calculate_most_dominant
      
      expect(dominant[:display]).to include('win rate')
    end
  end

  describe '#calculate_brick_wall' do
    it 'returns the fan with best goals against' do
      brick_wall = calculator.calculate_brick_wall
      
      expect(brick_wall).to have_key(:fan)
      expect(brick_wall).to have_key(:value)
      expect(brick_wall[:value]).to be_a(Numeric)
    end

    it 'displays goals against per game' do
      brick_wall = calculator.calculate_brick_wall
      
      expect(brick_wall[:display]).to include('goals against/game')
    end
  end

  describe '#calculate_glass_cannon' do
    it 'returns fan with high scoring but negative differential' do
      glass_cannon = calculator.calculate_glass_cannon
      
      # May be nil if no team fits the criteria
      if glass_cannon
        expect(glass_cannon).to have_key(:fan)
        expect(glass_cannon).to have_key(:value)
        expect(glass_cannon[:display]).to include('differential')
      end
    end
  end

  describe '#calculate_comeback_kid' do
    it 'returns fan with most OT/SO wins' do
      comeback_kid = calculator.calculate_comeback_kid
      
      # May be nil if no team has OT wins
      if comeback_kid
        expect(comeback_kid).to have_key(:fan)
        expect(comeback_kid).to have_key(:value)
        expect(comeback_kid[:value]).to be > 0
        expect(comeback_kid[:display]).to include('OT/SO wins')
      end
    end
  end

  describe '#calculate_all_stats' do
    it 'calculates all stats and stores in stats hash' do
      calculator.calculate_all_stats
      
      expect(calculator.stats).to have_key(:top_winners)
      expect(calculator.stats).to have_key(:top_losers)
      expect(calculator.stats).to have_key(:upcoming_fan_matchups)
      expect(calculator.stats).to have_key(:longest_win_streak)
      expect(calculator.stats).to have_key(:longest_lose_streak)
      expect(calculator.stats).to have_key(:best_point_differential)
      expect(calculator.stats).to have_key(:most_dominant)
      expect(calculator.stats).to have_key(:brick_wall)
      expect(calculator.stats).to have_key(:glass_cannon)
      expect(calculator.stats).to have_key(:comeback_kid)
    end

    it 'returns stats hash' do
      result = calculator.calculate_all_stats
      
      expect(result).to be_a(Hash)
      expect(result).to eq(calculator.stats)
    end
  end

  describe 'edge cases' do
    context 'when no fans are assigned' do
      let(:empty_manager_map) do
        { 'BOS' => 'N/A', 'FLA' => 'N/A', 'TOR' => 'N/A' }
      end

      it 'handles empty fan teams gracefully' do
        calc = BetStatsCalculator.new(teams, empty_manager_map, next_games)
        calc.calculate_all_stats
        
        expect(calc.stats[:top_winners]).to be_empty
        expect(calc.stats[:top_losers]).to be_empty
        expect(calc.stats[:upcoming_fan_matchups]).to be_empty
      end
    end

    context 'when teams have nil values' do
      let(:teams_with_nils) do
        [
          {
            'teamName' => { 'default' => 'Test Team' },
            'teamAbbrev' => { 'default' => 'TST' },
            'wins' => nil,
            'losses' => nil,
            'otLosses' => nil,
            'streakCode' => nil,
            'points' => nil,
            'leagueSequence' => nil,
            'wildcardSequence' => nil
          }
        ]
      end

      let(:nil_manager_map) { { 'TST' => 'TestFan' } }

      it 'handles nil values gracefully' do
        calc = BetStatsCalculator.new(teams_with_nils, nil_manager_map, {})
        calc.calculate_all_stats
        
        expect { calc.stats }.not_to raise_error
      end
    end
  end
end
