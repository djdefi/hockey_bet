require 'spec_helper'
require_relative '../lib/cup_path'

RSpec.describe CupPath do
  let(:teams) do
    %w[Atlantic Metropolitan].flat_map.with_index do |division, di|
      (1..8).map do |rank|
        {
          'conferenceName' => 'Eastern', 'divisionName' => division,
          'divisionSequence' => rank, 'conferenceSequence' => rank * 2 - di,
          'wildcardSequence' => rank > 3 ? (rank - 4) * 2 + di + 1 : 0,
          'gamesPlayed' => 20, 'teamAbbrev' => { 'default' => "#{division[0]}#{rank}" }
        }
      end
    end
  end

  it 'uses the fixed division bracket and sends WC2 to the better division winner' do
    conference = described_class.conferences(teams.shuffle).first
    expect(conference[:ready]).to be(true)
    expect(conference[:branches].map { |b| b[:teams].map { |t| t.dig('teamAbbrev', 'default') } })
      .to eq([%w[M1 M4 M2 M3], %w[A1 A4 A2 A3]])
    expect(conference[:branches].flat_map { |b| b[:teams] }.uniq.size).to eq(8)
  end

  it 'lets both wild cards cross into a different division branch without reseeding' do
    teams.find { |t| t.dig('teamAbbrev', 'default') == 'M4' }['wildcardSequence'] = 3
    teams.find { |t| t.dig('teamAbbrev', 'default') == 'A5' }['wildcardSequence'] = 2
    branches = described_class.conferences(teams).first[:branches]
    expect(branches[0][:teams][1].dig('teamAbbrev', 'default')).to eq('A5')
    expect(branches[1][:teams][1].dig('teamAbbrev', 'default')).to eq('A4')
  end

  it 'does not invent a bracket for missing seeds or a zero-game season' do
    expect(described_class.conferences(teams.reject { |t| t['wildcardSequence'] == 2 }).first[:ready]).to be(false)
    teams.each { |team| team['gamesPlayed'] = 0 }
    expect(described_class.conferences(teams).first[:ready]).to be(false)
    expect(described_class.conferences([])).to eq([])
  end
end
