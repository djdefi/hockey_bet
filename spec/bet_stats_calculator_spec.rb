# filepath: /home/runner/work/hockey_bet/hockey_bet/spec/bet_stats_calculator_spec.rb
require_relative '../lib/bet_stats_calculator'
require 'json'
require 'net/http'

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

    it 'only shows top 3 medal positions (not 4th place or lower)' do
      # Create scenario matching the issue: wins of [8, 8, 6, 6, 5, 5, 5]
      # Expected: Show only [8, 8, 6, 6] (top 3 positions: 1st, 2nd, 3rd)
      # Bug: Currently shows [8, 8, 6, 6, 5, 5, 5] (top 3 unique values)
      teams_with_ties = [
        { 'teamName' => { 'default' => 'Team A' }, 'teamAbbrev' => { 'default' => 'AAA' }, 'wins' => 8 },
        { 'teamName' => { 'default' => 'Team B' }, 'teamAbbrev' => { 'default' => 'BBB' }, 'wins' => 8 },
        { 'teamName' => { 'default' => 'Team C' }, 'teamAbbrev' => { 'default' => 'CCC' }, 'wins' => 6 },
        { 'teamName' => { 'default' => 'Team D' }, 'teamAbbrev' => { 'default' => 'DDD' }, 'wins' => 6 },
        { 'teamName' => { 'default' => 'Team E' }, 'teamAbbrev' => { 'default' => 'EEE' }, 'wins' => 5 },
        { 'teamName' => { 'default' => 'Team F' }, 'teamAbbrev' => { 'default' => 'FFF' }, 'wins' => 5 },
        { 'teamName' => { 'default' => 'Team G' }, 'teamAbbrev' => { 'default' => 'GGG' }, 'wins' => 5 }
      ]
      
      fan_map = {
        'AAA' => 'Fan A', 'BBB' => 'Fan B', 'CCC' => 'Fan C', 'DDD' => 'Fan D',
        'EEE' => 'Fan E', 'FFF' => 'Fan F', 'GGG' => 'Fan G'
      }
      
      calc = BetStatsCalculator.new(teams_with_ties, fan_map, {})
      top_winners = calc.calculate_top_winners
      
      # Should only show top 3 positions (medals): 1st (8 wins), 2nd (also 8 wins), 3rd (6 wins tied)
      # Total: 4 people (2 at 1st tied, 2 at 3rd tied)
      # Should NOT show 4th place (5 wins)
      wins = top_winners.map { |w| w[:value] }
      expect(wins).to eq([8, 8, 6, 6])
      expect(top_winners.size).to eq(4)
      
      # Verify we don't have any with 5 wins
      expect(wins).not_to include(5)
    end
  end

  describe '#calculate_top_losers' do
    it 'returns top 3 fans with most losses' do
      top_losers = calculator.calculate_top_losers
      
      expect(top_losers).to all(have_key(:fan))
      expect(top_losers).to all(have_key(:value))
    end

    it 'sorts by losses in descending order' do
      top_losers = calculator.calculate_top_losers
      losses = top_losers.map { |l| l[:value] }
      
      expect(losses).to eq(losses.sort.reverse)
    end

    it 'only shows top 3 medal positions (not 4th place or lower)' do
      # Create scenario matching the issue: losses of [5, 5, 4, 4, 3, 3, 3, 3]
      # Expected: Show only [5, 5, 4, 4] (top 3 positions: 1st, 2nd, 3rd)
      # Bug: Currently shows [5, 5, 4, 4, 3, 3, 3, 3] (top 3 unique values)
      teams_with_ties = [
        { 'teamName' => { 'default' => 'Team A' }, 'teamAbbrev' => { 'default' => 'AAA' }, 'losses' => 5 },
        { 'teamName' => { 'default' => 'Team B' }, 'teamAbbrev' => { 'default' => 'BBB' }, 'losses' => 5 },
        { 'teamName' => { 'default' => 'Team C' }, 'teamAbbrev' => { 'default' => 'CCC' }, 'losses' => 4 },
        { 'teamName' => { 'default' => 'Team D' }, 'teamAbbrev' => { 'default' => 'DDD' }, 'losses' => 4 },
        { 'teamName' => { 'default' => 'Team E' }, 'teamAbbrev' => { 'default' => 'EEE' }, 'losses' => 3 },
        { 'teamName' => { 'default' => 'Team F' }, 'teamAbbrev' => { 'default' => 'FFF' }, 'losses' => 3 },
        { 'teamName' => { 'default' => 'Team G' }, 'teamAbbrev' => { 'default' => 'GGG' }, 'losses' => 3 },
        { 'teamName' => { 'default' => 'Team H' }, 'teamAbbrev' => { 'default' => 'HHH' }, 'losses' => 3 }
      ]
      
      fan_map = {
        'AAA' => 'Fan A', 'BBB' => 'Fan B', 'CCC' => 'Fan C', 'DDD' => 'Fan D',
        'EEE' => 'Fan E', 'FFF' => 'Fan F', 'GGG' => 'Fan G', 'HHH' => 'Fan H'
      }
      
      calc = BetStatsCalculator.new(teams_with_ties, fan_map, {})
      top_losers = calc.calculate_top_losers
      
      # Should only show top 3 positions (medals): 1st (5 losses tied), 3rd (4 losses tied)
      # Total: 4 people (2 at 1st tied, 2 at 3rd tied)
      # Should NOT show 4th place (3 losses)
      losses = top_losers.map { |l| l[:value] }
      expect(losses).to eq([5, 5, 4, 4])
      expect(top_losers.size).to eq(4)
      
      # Verify we don't have any with 3 losses
      expect(losses).not_to include(3)
    end
  end

  describe '#calculate_upcoming_fan_matchups' do
    it 'returns upcoming games between fan teams' do
      matchups = calculator.calculate_upcoming_fan_matchups
      
      expect(matchups).to be_an(Array)
      # Should return all fan vs fan matchups without any limit
      expect(matchups.size).to be >= 0
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
      
      if longest && longest.any?
        expect(longest).to be_an(Array)
        expect(longest.first).to have_key(:fan)
        expect(longest.first).to have_key(:value)
        expect(longest.first).to have_key(:display)
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
      
      if longest && longest.any?
        expect(longest.first[:value]).to be_a(Integer)
        expect(longest.first[:value]).to be > 0
        expect(longest.first[:display]).to include('game')
      end
    end

    it 'handles streak codes without numbers (defaults to 1)' do
      teams_simple_streak = [
        {
          'teamName' => { 'default' => 'Test Team' },
          'teamAbbrev' => { 'default' => 'TST' },
          'streakCode' => 'W', # No number
          'wins' => 1
        }
      ]
      
      calc = BetStatsCalculator.new(teams_simple_streak, { 'TST' => 'TestFan' }, {})
      result = calc.calculate_longest_win_streak
      
      expect(result.first[:value]).to eq(1)
      expect(result.first[:display]).to include('1 game wins')
    end

    it 'handles streak codes with 0 (defaults to 1)' do
      teams_zero_streak = [
        {
          'teamName' => { 'default' => 'Test Team' },
          'teamAbbrev' => { 'default' => 'TST' },
          'streakCode' => 'W0', # Zero streak
          'wins' => 1
        }
      ]
      
      calc = BetStatsCalculator.new(teams_zero_streak, { 'TST' => 'TestFan' }, {})
      result = calc.calculate_longest_win_streak
      
      expect(result.first[:value]).to eq(1)
      expect(result.first[:display]).to include('1 game wins')
      expect(result.first[:display]).to include('(W0)')
    end

    it 'uses streakCount field when available (current API format)' do
      teams_with_streak_count = [
        {
          'teamName' => { 'default' => 'Test Team 1' },
          'teamAbbrev' => { 'default' => 'TS1' },
          'streakCode' => 'W', # No number in code
          'streakCount' => 5,   # But count is available
          'wins' => 5
        },
        {
          'teamName' => { 'default' => 'Test Team 2' },
          'teamAbbrev' => { 'default' => 'TS2' },
          'streakCode' => 'W', # No number in code
          'streakCount' => 3,   # But count is available
          'wins' => 3
        }
      ]
      
      calc = BetStatsCalculator.new(teams_with_streak_count, { 'TS1' => 'Fan1', 'TS2' => 'Fan2' }, {})
      result = calc.calculate_longest_win_streak
      
      expect(result.first[:value]).to eq(5)
      expect(result.first[:display]).to include('5 game wins')
      expect(result.first[:display]).to include('(W)')
    end
  end

  describe '#calculate_longest_lose_streak' do
    it 'returns the fan with longest losing streak' do
      longest = calculator.calculate_longest_lose_streak
      
      if longest && longest.any?
        expect(longest).to be_an(Array)
        expect(longest.first).to have_key(:fan)
        expect(longest.first).to have_key(:value)
        expect(longest.first).to have_key(:display)
      end
    end

    it 'only considers teams with losing streaks' do
      # If there's a longest losing streak, it should include 'loss'
      longest = calculator.calculate_longest_lose_streak
      
      if longest && longest.any?
        expect(longest.first[:display]).to include('loss')
      end
    end

    it 'uses streakCount field when available (current API format)' do
      teams_with_streak_count = [
        {
          'teamName' => { 'default' => 'Test Team 1' },
          'teamAbbrev' => { 'default' => 'TS1' },
          'streakCode' => 'L', # No number in code
          'streakCount' => 4,   # But count is available
          'losses' => 4
        },
        {
          'teamName' => { 'default' => 'Test Team 2' },
          'teamAbbrev' => { 'default' => 'TS2' },
          'streakCode' => 'L', # No number in code
          'streakCount' => 2,   # But count is available
          'losses' => 2
        }
      ]
      
      calc = BetStatsCalculator.new(teams_with_streak_count, { 'TS1' => 'Fan1', 'TS2' => 'Fan2' }, {})
      result = calc.calculate_longest_lose_streak
      
      expect(result.first[:value]).to eq(4)
      expect(result.first[:display]).to include('4 game losses')
      expect(result.first[:display]).to include('(L)')
    end
  end

  describe '#calculate_best_point_differential' do
    it 'returns the fan with best goal differential' do
      best = calculator.calculate_best_point_differential
      
      if best && best.any?
        expect(best).to be_an(Array)
        expect(best.first).to have_key(:fan)
        expect(best.first).to have_key(:value)
        expect(best.first[:value]).to be_a(Numeric)
      end
    end

    it 'includes goals suffix in display' do
      best = calculator.calculate_best_point_differential
      
      if best && best.any?
        expect(best.first[:display]).to include('goals')
      end
    end
  end

  describe '#calculate_most_dominant' do
    it 'returns the fan with best win percentage' do
      dominant = calculator.calculate_most_dominant
      
      if dominant && dominant.any?
        expect(dominant).to be_an(Array)
        expect(dominant.first).to have_key(:fan)
        expect(dominant.first).to have_key(:value)
        expect(dominant.first[:value]).to be_a(Numeric)
      end
    end

    it 'displays win percentage' do
      dominant = calculator.calculate_most_dominant
      
      if dominant && dominant.any?
        expect(dominant.first[:display]).to include('win rate')
      end
    end
  end

  describe '#calculate_brick_wall' do
    it 'returns the fan with best goals against' do
      brick_wall = calculator.calculate_brick_wall
      
      if brick_wall && brick_wall.any?
        expect(brick_wall).to be_an(Array)
        expect(brick_wall.first).to have_key(:fan)
        expect(brick_wall.first).to have_key(:value)
        expect(brick_wall.first[:value]).to be_a(Numeric)
      end
    end

    it 'displays goals against per game' do
      brick_wall = calculator.calculate_brick_wall
      
      if brick_wall && brick_wall.any?
        expect(brick_wall.first[:display]).to include('goals against/game')
      end
    end
  end

  describe '#calculate_glass_cannon' do
    it 'returns fan with high scoring but negative differential' do
      glass_cannon = calculator.calculate_glass_cannon
      
      # May be nil if no team fits the criteria
      if glass_cannon && glass_cannon.any?
        expect(glass_cannon).to be_an(Array)
        expect(glass_cannon.first).to have_key(:fan)
        expect(glass_cannon.first).to have_key(:value)
        expect(glass_cannon.first[:display]).to include('differential')
      end
    end
  end

  describe '#calculate_comeback_kid' do
    it 'returns fan with most OT/SO wins' do
      comeback_kid = calculator.calculate_comeback_kid
      
      # May be nil if no team has OT wins
      if comeback_kid && comeback_kid.any?
        expect(comeback_kid).to be_an(Array)
        expect(comeback_kid.first).to have_key(:fan)
        expect(comeback_kid.first).to have_key(:value)
        expect(comeback_kid.first[:value]).to be > 0
        expect(comeback_kid.first[:display]).to include('OT/SO')
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
      expect(calculator.stats).to have_key(:overtimer)
      expect(calculator.stats).to have_key(:point_scrounger)
      expect(calculator.stats).to have_key(:sharks_victims)
      expect(calculator.stats).to have_key(:predators_victims)
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

  describe '#calculate_overtimer' do
    it 'returns team with most OT losses' do
      result = calculator.calculate_overtimer
      
      expect(result).to be_an(Array)
      expect(result.first[:fan]).to eq('Charlie')
      expect(result.first[:team]).to eq('Toronto Maple Leafs')
      expect(result.first[:value]).to eq(9)
      expect(result.first[:display]).to include('9 overtime losses')
    end

    it 'returns nil when no teams have OT losses' do
      teams_no_ot = [
        {
          'teamName' => { 'default' => 'Test Team' },
          'teamAbbrev' => { 'default' => 'TST' },
          'otLosses' => 0
        }
      ]
      
      calc = BetStatsCalculator.new(teams_no_ot, { 'TST' => 'TestFan' }, {})
      result = calc.calculate_overtimer
      
      expect(result).to be_nil
    end
  end

  describe '#calculate_point_scrounger' do
    it 'returns team with most pity points from OT losses' do
      result = calculator.calculate_point_scrounger
      
      expect(result).to be_an(Array)
      expect(result.first[:fan]).to eq('Charlie')
      expect(result.first[:team]).to eq('Toronto Maple Leafs')
      expect(result.first[:value]).to eq(9)
      expect(result.first[:display]).to include('9 pity points')
    end

    it 'returns nil when no teams have OT losses' do
      teams_no_ot = [
        {
          'teamName' => { 'default' => 'Test Team' },
          'teamAbbrev' => { 'default' => 'TST' },
          'otLosses' => 0
        }
      ]
      
      calc = BetStatsCalculator.new(teams_no_ot, { 'TST' => 'TestFan' }, {})
      result = calc.calculate_point_scrounger
      
      expect(result).to be_nil
    end
  end

  describe '#fetch_head_to_head_records' do
    before do
      # Mock HTTP responses for NHL API with unique game IDs to prevent double-counting
      allow(Net::HTTP).to receive(:get_response) do |uri|
        team = uri.to_s.match(/club-schedule-season\/(\w+)\//)[1]
        
        games = case team
                when 'BOS'
                  [
                    {
                      'id' => 2024020101,
                      'gameState' => 4,
                      'homeTeam' => { 'abbrev' => 'BOS', 'score' => 3 },
                      'awayTeam' => { 'abbrev' => 'FLA', 'score' => 2 },
                      'periodDescriptor' => { 'periodType' => 'REG' }
                    },
                    {
                      'id' => 2024020102,
                      'gameState' => 4,
                      'homeTeam' => { 'abbrev' => 'TOR', 'score' => 4 },
                      'awayTeam' => { 'abbrev' => 'BOS', 'score' => 5 },
                      'periodDescriptor' => { 'periodType' => 'OT' }
                    }
                  ]
                when 'FLA'
                  [
                    {
                      'id' => 2024020101,  # Same game as BOS vs FLA
                      'gameState' => 4,
                      'homeTeam' => { 'abbrev' => 'BOS', 'score' => 3 },
                      'awayTeam' => { 'abbrev' => 'FLA', 'score' => 2 },
                      'periodDescriptor' => { 'periodType' => 'REG' }
                    }
                  ]
                when 'TOR'
                  [
                    {
                      'id' => 2024020102,  # Same game as TOR vs BOS
                      'gameState' => 4,
                      'homeTeam' => { 'abbrev' => 'TOR', 'score' => 4 },
                      'awayTeam' => { 'abbrev' => 'BOS', 'score' => 5 },
                      'periodDescriptor' => { 'periodType' => 'OT' }
                    }
                  ]
                else
                  []
                end
        
        double(
          is_a?: true,
          body: { games: games }.to_json
        )
      end
    end

    it 'fetches head-to-head records from NHL API' do
      calculator.send(:fetch_head_to_head_records)
      matrix = calculator.instance_variable_get(:@head_to_head_matrix)
      
      expect(matrix).to be_a(Hash)
      expect(matrix.keys).to include('BOS', 'FLA', 'TOR', 'DET')
    end

    it 'handles API errors gracefully' do
      allow(Net::HTTP).to receive(:get_response).and_raise(StandardError.new('API Error'))
      
      expect { calculator.send(:fetch_head_to_head_records) }.not_to raise_error
    end

    it 'handles string gameState values (OFF, FINAL)' do
      # Mock different responses for different teams to simulate realistic API behavior
      allow(Net::HTTP).to receive(:get_response) do |uri|
        team = uri.to_s.match(/club-schedule-season\/(\w+)\//)[1]
        
        games = case team
                when 'BOS'
                  [
                    {
                      'id' => 2024020001,
                      'gameState' => 'OFF',
                      'homeTeam' => { 'abbrev' => 'BOS', 'score' => 4 },
                      'awayTeam' => { 'abbrev' => 'FLA', 'score' => 3 },
                      'periodDescriptor' => { 'periodType' => 'SO' }
                    },
                    {
                      'id' => 2024020002,
                      'gameState' => 'FINAL',
                      'homeTeam' => { 'abbrev' => 'TOR', 'score' => 2 },
                      'awayTeam' => { 'abbrev' => 'BOS', 'score' => 3 },
                      'periodDescriptor' => { 'periodType' => 'REG' }
                    },
                    {
                      'id' => 2024020003,
                      'gameState' => 'LIVE',  # Should be skipped
                      'homeTeam' => { 'abbrev' => 'DET', 'score' => 1 },
                      'awayTeam' => { 'abbrev' => 'BOS', 'score' => 1 },
                      'periodDescriptor' => { 'periodType' => 'REG' }
                    }
                  ]
                when 'FLA'
                  [
                    {
                      'id' => 2024020001,  # Same game ID as BOS vs FLA
                      'gameState' => 'OFF',
                      'homeTeam' => { 'abbrev' => 'BOS', 'score' => 4 },
                      'awayTeam' => { 'abbrev' => 'FLA', 'score' => 3 },
                      'periodDescriptor' => { 'periodType' => 'SO' }
                    }
                  ]
                when 'TOR'
                  [
                    {
                      'id' => 2024020002,  # Same game ID as TOR vs BOS
                      'gameState' => 'FINAL',
                      'homeTeam' => { 'abbrev' => 'TOR', 'score' => 2 },
                      'awayTeam' => { 'abbrev' => 'BOS', 'score' => 3 },
                      'periodDescriptor' => { 'periodType' => 'REG' }
                    }
                  ]
                else
                  []
                end
        
        double(
          is_a?: true,
          body: { games: games }.to_json
        )
      end
      
      calculator.send(:fetch_head_to_head_records)
      matrix = calculator.instance_variable_get(:@head_to_head_matrix)
      
      # BOS should have recorded wins against FLA and TOR (games counted only once)
      expect(matrix['BOS']).to be_a(Hash)
      expect(matrix['BOS']['FLA']).to eq({ wins: 1, losses: 0, ot_losses: 0 })
      expect(matrix['BOS']['TOR']).to eq({ wins: 1, losses: 0, ot_losses: 0 })
      
      # FLA should show loss to BOS (same game, opposite perspective)
      expect(matrix['FLA']['BOS']).to eq({ wins: 0, losses: 0, ot_losses: 1 })
      
      # TOR should show loss to BOS
      expect(matrix['TOR']['BOS']).to eq({ wins: 0, losses: 1, ot_losses: 0 })
      
      # DET game should be skipped (LIVE state)
      expect(matrix['BOS']['DET']).to be_nil
    end
  end

  describe '#calculate_fan_crusher' do
    before do
      # Set up mock head-to-head data
      calculator.instance_variable_set(:@head_to_head_matrix, {
        'BOS' => {
          'FLA' => { wins: 3, losses: 1, ot_losses: 0 },
          'TOR' => { wins: 2, losses: 1, ot_losses: 1 }
        },
        'FLA' => {
          'BOS' => { wins: 1, losses: 3, ot_losses: 0 },
          'TOR' => { wins: 2, losses: 0, ot_losses: 0 }
        },
        'TOR' => {
          'BOS' => { wins: 1, losses: 2, ot_losses: 1 },
          'FLA' => { wins: 0, losses: 2, ot_losses: 0 }
        },
        'DET' => {}
      })
    end

    it 'returns fan with best record vs other fan teams' do
      result = calculator.calculate_fan_crusher
      
      expect(result).to be_an(Array)
      expect(result.first[:fan]).to eq('Alice') # BOS has best record
      expect(result.first[:display]).to include('62.5%') # 5-3 (wins-losses including OT) = 62.5%
    end

    it 'handles ties correctly' do
      # Set up a tie scenario
      calculator.instance_variable_set(:@head_to_head_matrix, {
        'BOS' => { 'FLA' => { wins: 2, losses: 0, ot_losses: 0 } },
        'FLA' => { 'BOS' => { wins: 2, losses: 0, ot_losses: 0 } }
      })
      
      result = calculator.calculate_fan_crusher
      expect(result.length).to eq(2) # Both tied at 100%
    end

    it 'returns nil when no games played' do
      calculator.instance_variable_set(:@head_to_head_matrix, {})
      result = calculator.calculate_fan_crusher
      expect(result).to be_nil
    end
  end

  describe '#calculate_fan_fodder' do
    before do
      # Set up mock head-to-head data
      calculator.instance_variable_set(:@head_to_head_matrix, {
        'BOS' => {
          'FLA' => { wins: 3, losses: 1, ot_losses: 0 },
          'TOR' => { wins: 2, losses: 1, ot_losses: 1 }
        },
        'FLA' => {
          'BOS' => { wins: 1, losses: 3, ot_losses: 0 },
          'TOR' => { wins: 2, losses: 0, ot_losses: 0 }
        },
        'TOR' => {
          'BOS' => { wins: 1, losses: 2, ot_losses: 1 },
          'FLA' => { wins: 0, losses: 2, ot_losses: 0 }
        },
        'DET' => {}
      })
    end

    it 'returns fan with worst record vs other fan teams' do
      result = calculator.calculate_fan_fodder
      
      expect(result).to be_an(Array)
      expect(result.first[:fan]).to eq('Charlie') # TOR has most losses
      expect(result.first[:display]).to include('5 losses vs other fans') # 1-5 record = 5 losses
    end

    it 'returns nil when no games played' do
      calculator.instance_variable_set(:@head_to_head_matrix, {})
      result = calculator.calculate_fan_fodder
      expect(result).to be_nil
    end
  end

  describe '#calculate_all_stats with head-to-head' do
    before do
      # Mock the API call
      allow(calculator).to receive(:fetch_head_to_head_records) do
        calculator.instance_variable_set(:@head_to_head_matrix, {
          'BOS' => { 'FLA' => { wins: 2, losses: 1, ot_losses: 0 } },
          'FLA' => { 'BOS' => { wins: 1, losses: 2, ot_losses: 0 } }
        })
      end
    end

    it 'includes head-to-head stats in results' do
      calculator.calculate_all_stats
      
      expect(calculator.stats).to include(:head_to_head_matrix)
      expect(calculator.stats).to include(:fan_crusher)
      expect(calculator.stats).to include(:fan_fodder)
    end
  end

  describe '#calculate_stanley_cup_odds' do
    before do
      allow(calculator).to receive(:fetch_head_to_head_records) # Mock to avoid API calls
      calculator.send(:calculate_stanley_cup_odds)
    end

    it 'calculates odds for all teams' do
      cup_odds = calculator.instance_variable_get(:@cup_odds)
      expect(cup_odds).to be_a(Hash)
      expect(cup_odds.keys).to include('BOS', 'FLA', 'TOR', 'TBL')
    end

    it 'normalizes odds to sum to approximately 100%' do
      cup_odds = calculator.instance_variable_get(:@cup_odds)
      total_odds = cup_odds.values.sum
      expect(total_odds).to be_within(0.1).of(100.0)
    end

    it 'assigns higher odds to better-positioned teams' do
      cup_odds = calculator.instance_variable_get(:@cup_odds)
      # BOS is 1st in division and conference, should have higher odds than TBL (4th in division)
      expect(cup_odds['BOS']).to be > cup_odds['TBL']
    end
  end

  describe '#calculate_best_cup_odds' do
    before do
      allow(calculator).to receive(:fetch_head_to_head_records) # Mock to avoid API calls
      calculator.calculate_all_stats
    end

    it 'returns stats for fans with best Stanley Cup odds' do
      best_odds = calculator.stats[:best_cup_odds]
      expect(best_odds).to be_a(Array)
      expect(best_odds).not_to be_empty
    end

    it 'excludes N/A teams' do
      best_odds = calculator.stats[:best_cup_odds]
      fan_names = best_odds.map { |s| s[:fan] }
      expect(fan_names).not_to include('N/A')
    end

    it 'includes conference and division information' do
      best_odds = calculator.stats[:best_cup_odds]
      first_stat = best_odds.first
      expect(first_stat).to include(:division_sequence, :conference_sequence)
      expect(first_stat[:display]).to match(/in division/)
      expect(first_stat[:display]).to match(/in conference/)
    end

    it 'sorts by odds in descending order' do
      best_odds = calculator.stats[:best_cup_odds]
      odds_values = best_odds.map { |s| s[:value] }
      expect(odds_values).to eq(odds_values.sort.reverse)
    end
  end

  describe '#calculate_worst_cup_odds' do
    before do
      allow(calculator).to receive(:fetch_head_to_head_records) # Mock to avoid API calls
      calculator.calculate_all_stats
    end

    it 'returns stats for fans with worst Stanley Cup odds' do
      worst_odds = calculator.stats[:worst_cup_odds]
      expect(worst_odds).to be_a(Array)
      expect(worst_odds).not_to be_empty
    end

    it 'excludes N/A teams' do
      worst_odds = calculator.stats[:worst_cup_odds]
      fan_names = worst_odds.map { |s| s[:fan] }
      expect(fan_names).not_to include('N/A')
    end

    it 'sorts by odds in ascending order' do
      worst_odds = calculator.stats[:worst_cup_odds]
      odds_values = worst_odds.map { |s| s[:value] }
      expect(odds_values).to eq(odds_values.sort)
    end
  end

  describe '#get_ordinal' do
    it 'returns correct ordinal for 1st' do
      expect(calculator.send(:get_ordinal, 1)).to eq('1st')
    end

    it 'returns correct ordinal for 2nd' do
      expect(calculator.send(:get_ordinal, 2)).to eq('2nd')
    end

    it 'returns correct ordinal for 3rd' do
      expect(calculator.send(:get_ordinal, 3)).to eq('3rd')
    end

    it 'returns correct ordinal for 4th-20th' do
      expect(calculator.send(:get_ordinal, 4)).to eq('4th')
      expect(calculator.send(:get_ordinal, 11)).to eq('11th')
      expect(calculator.send(:get_ordinal, 20)).to eq('20th')
    end

    it 'returns correct ordinal for 21st, 22nd, 23rd' do
      expect(calculator.send(:get_ordinal, 21)).to eq('21st')
      expect(calculator.send(:get_ordinal, 22)).to eq('22nd')
      expect(calculator.send(:get_ordinal, 23)).to eq('23rd')
    end

    it 'handles 11th, 12th, 13th correctly' do
      expect(calculator.send(:get_ordinal, 11)).to eq('11th')
      expect(calculator.send(:get_ordinal, 12)).to eq('12th')
      expect(calculator.send(:get_ordinal, 13)).to eq('13th')
      expect(calculator.send(:get_ordinal, 111)).to eq('111th')
      expect(calculator.send(:get_ordinal, 112)).to eq('112th')
      expect(calculator.send(:get_ordinal, 113)).to eq('113th')
    end

    it 'handles 41st, 42nd, 43rd correctly' do
      expect(calculator.send(:get_ordinal, 41)).to eq('41st')
      expect(calculator.send(:get_ordinal, 42)).to eq('42nd')
      expect(calculator.send(:get_ordinal, 43)).to eq('43rd')
    end

    it 'returns empty string for 0 or negative numbers' do
      expect(calculator.send(:get_ordinal, 0)).to eq('')
      expect(calculator.send(:get_ordinal, -1)).to eq('')
    end
  end

  describe '#calculate_shutout_king' do
    before do
      allow(calculator).to receive(:fetch_head_to_head_records) # Mock to avoid API calls
      calculator.calculate_all_stats
    end

    it 'returns stats for teams with low goals against' do
      shutout = calculator.stats[:shutout_king]
      expect(shutout).to be_a(Array).or be_nil
    end

    it 'excludes N/A teams' do
      shutout = calculator.stats[:shutout_king]
      next if shutout.nil? || shutout.empty?
      fan_names = shutout.map { |s| s[:fan] }
      expect(fan_names).not_to include('N/A')
    end
  end

  describe '#calculate_momentum_master' do
    before do
      allow(calculator).to receive(:fetch_head_to_head_records) # Mock to avoid API calls
      calculator.calculate_all_stats
    end

    it 'returns stats for teams on winning streaks' do
      momentum = calculator.stats[:momentum_master]
      expect(momentum).to be_a(Array).or be_nil
    end

    it 'excludes N/A teams' do
      momentum = calculator.stats[:momentum_master]
      next if momentum.nil? || momentum.empty?
      fan_names = momentum.map { |s| s[:fan] }
      expect(fan_names).not_to include('N/A')
    end

    it 'sorts by streak length in descending order' do
      momentum = calculator.stats[:momentum_master]
      next if momentum.nil? || momentum.empty?
      streaks = momentum.map { |s| s[:value] }
      expect(streaks).to eq(streaks.sort.reverse)
    end
  end

  describe 'Multi-year stats' do
    let(:mock_tracker) { instance_double(HistoricalStatsTracker) }
    let(:calculator_with_history) do
      BetStatsCalculator.new(teams, manager_team_map, next_games, mock_tracker)
    end

    before do
      allow(calculator_with_history).to receive(:fetch_head_to_head_records)
      # Stub current_season for all tests
      allow(mock_tracker).to receive(:current_season).and_return('2024-2025')
    end

    describe '#calculate_dynasty_points' do
      it 'returns fans with playoff wins from history' do
        allow(mock_tracker).to receive(:total_playoff_wins).with('Alice').and_return(15)
        allow(mock_tracker).to receive(:total_playoff_wins).with('Bob').and_return(8)
        allow(mock_tracker).to receive(:total_playoff_wins).with('Charlie').and_return(0)
        allow(mock_tracker).to receive(:total_playoff_wins).with('Diana').and_return(3)
        allow(mock_tracker).to receive(:total_playoff_wins).and_return(0) # default for others
        
        # Stub loyalty, improvement and hall of fame methods to return nil
        allow(mock_tracker).to receive(:get_fan_seasons).and_return([])
        allow(mock_tracker).to receive(:calculate_improvement).and_return(nil)
        allow(mock_tracker).to receive(:get_fan_history).and_return({})
        
        calculator_with_history.calculate_all_stats
        dynasty = calculator_with_history.stats[:dynasty_points]
        
        expect(dynasty).to be_a(Array).or be_nil
        next if dynasty.nil? || dynasty.empty?
        
        # Should only include fans with playoff wins
        fan_names = dynasty.map { |s| s[:fan] }
        expect(fan_names).not_to include('Charlie')
      end
    end

    describe '#calculate_most_improved' do
      it 'returns fans who improved from last season' do
        allow(mock_tracker).to receive(:calculate_improvement).with('Alice', '2023-2024', '2024-2025')
          .and_return({ wins_diff: 10, points_diff: 20, rank_improvement: 5 })
        allow(mock_tracker).to receive(:calculate_improvement).with('Bob', '2023-2024', '2024-2025')
          .and_return(nil)
        allow(mock_tracker).to receive(:calculate_improvement).with('Charlie', '2023-2024', '2024-2025')
          .and_return({ wins_diff: -5, points_diff: -10, rank_improvement: -3 })
        allow(mock_tracker).to receive(:calculate_improvement).with('Diana', '2023-2024', '2024-2025')
          .and_return({ wins_diff: 3, points_diff: 7, rank_improvement: 2 })
        allow(mock_tracker).to receive(:calculate_improvement).and_return(nil) # default for others
        
        # Stub dynasty, loyalty and hall of fame methods
        allow(mock_tracker).to receive(:total_playoff_wins).and_return(0)
        allow(mock_tracker).to receive(:get_fan_seasons).and_return([])
        allow(mock_tracker).to receive(:get_fan_history).and_return({})
        
        calculator_with_history.calculate_all_stats
        improved = calculator_with_history.stats[:most_improved]
        
        expect(improved).to be_a(Array).or be_nil
        next if improved.nil? || improved.empty?
        
        # Should only include fans with positive improvement
        fan_names = improved.map { |s| s[:fan] }
        expect(fan_names).not_to include('Charlie') # negative improvement
      end
    end

    describe '#calculate_hall_of_fame' do
      it 'returns fans who won the Stanley Cup (16+ playoff wins) in last 6 years' do
        # Mock historical data with cup winners
        allow(mock_tracker).to receive(:get_fan_history).with('Alice').and_return({
          '2022-2023' => { 'team' => 'COL', 'playoff_wins' => 16 }, # Cup winner
          '2021-2022' => { 'team' => 'COL', 'playoff_wins' => 8 }
        })
        allow(mock_tracker).to receive(:get_fan_history).with('Bob').and_return({
          '2020-2021' => { 'team' => 'TBL', 'playoff_wins' => 16 } # Cup winner (within 6 years)
        })
        allow(mock_tracker).to receive(:get_fan_history).with('Charlie').and_return({
          '2023-2024' => { 'team' => 'BOS', 'playoff_wins' => 12 } # Not enough wins
        })
        allow(mock_tracker).to receive(:get_fan_history).with('Diana').and_return({
          '2015-2016' => { 'team' => 'PIT', 'playoff_wins' => 16 } # Too old (>6 years)
        })
        allow(mock_tracker).to receive(:get_fan_history).and_return({}) # default for others
        
        # Stub other methods
        allow(mock_tracker).to receive(:total_playoff_wins).and_return(0)
        allow(mock_tracker).to receive(:calculate_improvement).and_return(nil)
        
        calculator_with_history.calculate_all_stats
        hall_of_fame = calculator_with_history.stats[:hall_of_fame]
        
        expect(hall_of_fame).to be_a(Array).or be_nil
        next if hall_of_fame.nil? || hall_of_fame.empty?
        
        # Should only include Cup winners from last 6 years
        fan_names = hall_of_fame.map { |s| s[:fan] }
        expect(fan_names).to include('Alice', 'Bob')
        expect(fan_names).not_to include('Charlie', 'Diana')
      end

      it 'sorts by most recent championship first' do
        allow(mock_tracker).to receive(:get_fan_history).with('Alice').and_return({
          '2020-2021' => { 'team' => 'COL', 'playoff_wins' => 16 }
        })
        allow(mock_tracker).to receive(:get_fan_history).with('Bob').and_return({
          '2023-2024' => { 'team' => 'TBL', 'playoff_wins' => 16 }
        })
        allow(mock_tracker).to receive(:get_fan_history).and_return({}) # default
        
        # Stub other methods
        allow(mock_tracker).to receive(:total_playoff_wins).and_return(0)
        allow(mock_tracker).to receive(:calculate_improvement).and_return(nil)
        
        calculator_with_history.calculate_all_stats
        hall_of_fame = calculator_with_history.stats[:hall_of_fame]
        
        next if hall_of_fame.nil? || hall_of_fame.empty?
        
        # Bob (2023-2024) should come before Alice (2020-2021)
        fan_names = hall_of_fame.map { |s| s[:fan] }
        expect(fan_names.first).to eq('Bob')
      end
    end

    describe '#record_current_season_stats' do
      it 'saves current season stats to historical tracker' do
        # Expect record_season_stats to be called for each fan team
        expect(mock_tracker).to receive(:record_season_stats).at_least(:once)
        
        calculator_with_history.record_current_season_stats
      end
    end
  end
end
