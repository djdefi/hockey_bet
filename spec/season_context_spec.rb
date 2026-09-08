require 'spec_helper'
require 'tmpdir'
require_relative '../lib/season_context'

RSpec.describe SeasonContext do
  let(:teams) { [{ 'seasonId' => 20252026 }] }

  def context(date, metadata = {})
    described_class.new(teams: teams, schedule_metadata: metadata, today: Date.iso8601(date))
  end

  it 'uses the NHL schedule boundaries rather than guessing opening day' do
    metadata = { 'regularSeasonStartDate' => '2026-10-07', 'playoffEndDate' => '2027-06-20' }
    expect(context('2026-10-06', metadata)).to be_offseason
    expect(context('2026-10-07', metadata)).not_to be_offseason
    expect(context('2027-05-01', metadata)).not_to be_offseason
    expect(context('2027-06-21', metadata)).to be_offseason
  end

  it 'treats summer and a prior-season October snapshot as offseason without schedule metadata' do
    expect(context('2026-09-07')).to be_offseason
    expect(context('2026-10-01')).to be_offseason
    expect(context('2026-04-09')).not_to be_offseason
  end

  it 'labels the actual standings season separately from the news window' do
    season = context('2026-09-07')
    expect(season.standings_label).to eq('2025/26')
    expect(season.news_since).to eq(Date.new(2026, 6, 1))
  end

  it 'reports invalid schedule dates and falls back without inventing a season label' do
    expect { context('2026-09-07', { 'regularSeasonStartDate' => 'not a date' }) }
      .to output(/Invalid NHL season boundary/).to_stderr
    expect(described_class.new(teams: []).standings_label).to eq('Available season')
  end

  it 'does not write completed-season points into new offseason history' do
    Dir.mktmpdir do |directory|
      stub_const('DATA_DIR', File.join(directory, 'data'))
      processor = StandingsProcessor.new
      processor.instance_variable_set(:@season_context, context('2026-09-07'))
      allow(processor).to receive(:render_template).and_return('<html lang="en"></html>')
      expect_any_instance_of(StandingsHistoryTracker).not_to receive(:record_current_standings)
      processor.render_output(File.join(directory, 'site', 'index.html'))
      expect(JSON.parse(File.read(File.join(DATA_DIR, 'standings_history.json')))).to eq([])
    end
  end
end
