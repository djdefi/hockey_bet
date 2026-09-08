require 'spec_helper'
require 'tmpdir'
require_relative '../lib/offseason_news'

RSpec.describe OffseasonNews do
  let(:now) { Time.utc(2026, 9, 7, 20) }
  let(:since) { Date.new(2026, 6, 1) }
  let(:teams) { [{ 'teamAbbrev' => { 'default' => 'COL' }, 'teamName' => { 'default' => 'Colorado Avalanche' } }] }
  let(:fans) { { 'COL' => 'Jeff' } }
  let(:url) { "#{described_class::ENDPOINT}?context.slug=teamid-21&$limit=100&$sort=contentDate:desc" }
  let(:item) do
    { 'headline' => 'Avalanche Sign Player', 'title' => 'internal-title', 'slug' => 'avalanche-sign-player',
      'contentDate' => '2026-09-04T18:00:00Z', 'context' => { 'slug' => 'teamid-21' },
      'fields' => { 'description' => '<p>Official &amp; dated description.</p>' }, 'tags' => [] }
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @cache_path = File.join(dir, 'news.json')
      example.run
    end
  end

  def response(items)
    double(code: 200, body: JSON.generate('items' => items))
  end

  def fetch
    described_class.new(cache_path: @cache_path, now: now).fetch(teams, fans, since: since)
  end

  it 'uses the verified endpoint and retains publisher title, date, link and brief' do
    expect(HTTParty).to receive(:get).with(url, timeout: 8, headers: { 'Accept' => 'application/json' })
                                   .and_return(response([item]))
    report = fetch.first
    expect(report['status']).to eq('fresh')
    expect(report['articles'].first).to include(
      'title' => 'Avalanche Sign Player', 'published_at' => '2026-09-04T18:00:00Z',
      'url' => 'https://www.nhl.com/avalanche/news/avalanche-sign-player',
      'summary' => 'Official & dated description.', 'roster_news' => true
    )
    expect(JSON.parse(File.read(@cache_path))['COL']['updated_at']).to eq(now.iso8601)
  end

  it 'filters wrong teams, old and future stories, unsafe slugs, missing dates and duplicates' do
    items = [item, item, item.merge('contentDate' => '2025-08-01T12:00:00Z'),
             item.merge('contentDate' => '2026-09-08T12:00:00Z'),
             item.merge('context' => { 'slug' => 'teamid-7' }),
             item.merge('slug' => '../bad?url=<script>'), item.reject { |key, _| key == 'contentDate' }]
    allow(HTTParty).to receive(:get).and_return(response(items))
    expect { @report = fetch.first }.to output(/Skipping invalid NHL news item/).to_stderr
    expect(@report['articles'].length).to eq(1)
  end

  it 'keeps recent roster coverage even when newer general reports exist' do
    stories = (1..6).map do |day|
      item.merge('headline' => 'Training camp report', 'slug' => "camp-#{day}",
                 'contentDate' => "2026-09-0#{day}T12:00:00Z")
    end
    allow(HTTParty).to receive(:get).and_return(response(stories + [item.merge('contentDate' => '2026-08-01T12:00:00Z')]))
    titles = fetch.first['articles'].map { |story| story['title'] }
    expect(titles.length).to eq(4)
    expect(titles).to include('Avalanche Sign Player')
  end

  it 'shows the last successful snapshot with its original check time on failure' do
    allow(HTTParty).to receive(:get).and_return(response([item]))
    fetch
    allow(HTTParty).to receive(:get).and_raise(Net::ReadTimeout)
    later = described_class.new(cache_path: @cache_path, now: now + 3600)
    expect { @report = later.fetch(teams, fans, since: since).first }.to output(/unavailable/).to_stderr
    expect(@report).to include('status' => 'cached', 'updated_at' => now.iso8601)
    expect(@report['articles'].first['title']).to eq(item['headline'])
  end

  it 'keeps good cached reports when the entire new feed is malformed' do
    allow(HTTParty).to receive(:get).and_return(response([item]))
    fetch
    allow(HTTParty).to receive(:get).and_return(response([{ 'headline' => 'No publication date' }]))
    expect { @report = fetch.first }.to output(/No valid stories/).to_stderr
    expect(@report['status']).to eq('cached')
    expect(@report['articles'].first['title']).to eq(item['headline'])
  end

  it 'distinguishes valid empty coverage from unavailable data and discards broken caches' do
    allow(HTTParty).to receive(:get).and_return(response([]))
    expect(fetch.first).to include('status' => 'fresh', 'articles' => [])
    File.write(@cache_path, 'broken JSON')
    allow(HTTParty).to receive(:get).and_return(double(code: 503, body: 'unavailable'))
    expect { @report = fetch.first }.to output(/cache ignored.*unavailable/m).to_stderr
    expect(@report).to include('status' => 'unavailable', 'articles' => [])
    expect(@report).not_to have_key('updated_at')
  end

  it 'uses Utah context 68 and the official utah URL, without fetching unassigned teams' do
    teams = [{ 'teamAbbrev' => { 'default' => 'UTA' }, 'teamName' => { 'default' => 'Utah Mammoth' } }]
    expect(HTTParty).to receive(:get).with(/context.slug=teamid-68/, anything)
                                   .and_return(response([item.merge('context' => { 'slug' => 'teamid-68' })]))
    report = described_class.new(cache_path: @cache_path, now: now).fetch(teams, { 'UTA' => 'Tyler' }, since: since).first
    expect(report['articles'].first['url']).to start_with('https://www.nhl.com/utah/news/')
    expect(HTTParty).not_to receive(:get)
    expect(described_class.new(cache_path: @cache_path, now: now).fetch(teams, { 'UTA' => 'N/A' }, since: since)).to eq([])
  end
end
