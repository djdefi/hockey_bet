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
      # Mock HTTP responses for NHL API
      allow(Net::HTTP).to receive(:get_response).and_return(double(
        is_a?: true,
        body: {
          games: [
            {
              'gameState' => 4,
              'homeTeam' => { 'abbrev' => 'BOS', 'score' => 3 },
              'awayTeam' => { 'abbrev' => 'FLA', 'score' => 2 },
              'periodDescriptor' => { 'periodType' => 'REG' }
            },
            {
              'gameState' => 4,
              'homeTeam' => { 'abbrev' => 'TOR', 'score' => 4 },
              'awayTeam' => { 'abbrev' => 'BOS', 'score' => 5 },
              'periodDescriptor' => { 'periodType' => 'OT' }
            }
          ]
        }.to_json
      ))
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
      allow(Net::HTTP).to receive(:get_response).and_return(double(
        is_a?: true,
        body: {
          games: [
            {
              'gameState' => 'OFF',
              'homeTeam' => { 'abbrev' => 'BOS', 'score' => 4 },
              'awayTeam' => { 'abbrev' => 'FLA', 'score' => 3 },
              'periodDescriptor' => { 'periodType' => 'SO' }
            },
            {
              'gameState' => 'FINAL',
              'homeTeam' => { 'abbrev' => 'TOR', 'score' => 2 },
              'awayTeam' => { 'abbrev' => 'BOS', 'score' => 3 },
              'periodDescriptor' => { 'periodType' => 'REG' }
            },
            {
              'gameState' => 'LIVE',  # Should be skipped
              'homeTeam' => { 'abbrev' => 'DET', 'score' => 1 },
              'awayTeam' => { 'abbrev' => 'BOS', 'score' => 1 },
              'periodDescriptor' => { 'periodType' => 'REG' }
            }
          ]
        }.to_json
      ))
      
      calculator.send(:fetch_head_to_head_records)
      matrix = calculator.instance_variable_get(:@head_to_head_matrix)
      
      # BOS should have recorded the games with string gameState
      expect(matrix['BOS']).to be_a(Hash)
      expect(matrix['BOS']['FLA']).to eq({ wins: 1, losses: 0, ot_losses: 0 })
      expect(matrix['BOS']['TOR']).to eq({ wins: 1, losses: 0, ot_losses: 0 })
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
      expect(result.first[:fan]).to eq('Charlie') # TOR has worst record
      expect(result.first[:display]).to include('16.7%') # 1-5 (wins-losses including OT) = 16.7%
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
end
