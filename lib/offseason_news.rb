require 'httparty'
require 'json'
require 'time'
require 'date'
require 'cgi'
require 'fileutils'

class OffseasonNews
  class FeedError < StandardError; end

  # Forge team contexts and club URLs verified against NHL news-page canonicals.
  SOURCES = {
    'COL' => [21, 'avalanche'], 'BUF' => [7, 'sabres'], 'MIN' => [30, 'wild'],
    'WSH' => [15, 'capitals'], 'VGK' => [54, 'goldenknights'], 'UTA' => [68, 'utah'],
    'ANA' => [24, 'ducks'], 'LAK' => [26, 'kings'], 'NJD' => [1, 'devils'],
    'NSH' => [18, 'predators'], 'SJS' => [28, 'sharks'], 'WPG' => [52, 'jets'],
    'SEA' => [55, 'kraken']
  }.freeze
  ENDPOINT = 'https://forge-dapi.d3.nhle.com/v2/content/en-us/stories'
  ROSTER_HEADLINE = /\b(?:signs?|signed|re-signs?|acquires?|acquired|trades?|traded|contract extension|waivers|roster)\b/i
  NETWORK_ERRORS = [FeedError, JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout,
                    SocketError, OpenSSL::SSL::SSLError, Errno::ECONNRESET, Errno::ECONNREFUSED].freeze

  def initialize(cache_path:, now: Time.now.utc)
    @cache_path = cache_path
    @now = now
  end

  def fetch(teams, fan_map, since:)
    cache = read_cache
    reports = teams.filter_map do |team|
      abbrev = team.dig('teamAbbrev', 'default')
      fan = fan_map[abbrev]
      next if fan.nil? || fan == 'N/A'

      source = SOURCES[abbrev]
      news_url = source ? "https://www.nhl.com/#{source[1]}/news" : 'https://www.nhl.com/news'
      report = { 'abbrev' => abbrev, 'team' => team.dig('teamName', 'default'), 'fan' => fan,
                 'news_url' => news_url, 'status' => 'unavailable', 'articles' => [] }
      begin
        raise FeedError, "No official news feed configured for #{abbrev}" unless source

        # Forge ignores percent-encoded $ parameter names; keep them literal.
        url = "#{ENDPOINT}?context.slug=teamid-#{source[0]}&$limit=100&$sort=contentDate:desc"
        response = HTTParty.get(url, timeout: 8, headers: { 'Accept' => 'application/json' })
        raise FeedError, "HTTP #{response.code}" unless response.code == 200

        payload = JSON.parse(response.body)
        raise FeedError, 'Expected a list of stories' unless payload.is_a?(Hash) && payload['items'].is_a?(Array)

        invalid_count = 0
        stories = payload['items'].filter_map do |item|
          normalize(item, source, since)
        rescue FeedError => error
          invalid_count += 1
          warn "Skipping invalid NHL news item: #{error.message}"
          nil
        end
        raise FeedError, 'No valid stories in malformed feed' if stories.empty? && invalid_count.positive?

        stories = stories.uniq { |story| story['url'] }.sort_by { |story| story['published_at'] }.reverse
        # Keep current reports and roster coverage, without claiming a full moves ledger.
        selected = (stories.first(2) + stories.select { |story| story['roster_news'] }.first(2) + stories.first(4))
                   .uniq { |story| story['url'] }.first(4)
        selected = selected.sort_by { |story| [story['roster_news'] ? 0 : 1, -Time.iso8601(story['published_at']).to_i] }
        cache[abbrev] = { 'updated_at' => @now.iso8601, 'articles' => selected }
        report.merge!(cache[abbrev]).merge!('status' => 'fresh')
      rescue *NETWORK_ERRORS => error
        warn "Offseason news unavailable for #{abbrev}: #{error.message}"
        previous = cached_report(cache[abbrev], news_url, since)
        report.merge!(previous).merge!('status' => 'cached') if previous
      end
      report
    end
    FileUtils.mkdir_p(File.dirname(@cache_path))
    File.write("#{@cache_path}.tmp", JSON.pretty_generate(cache) + "\n")
    File.rename("#{@cache_path}.tmp", @cache_path)
    reports.sort_by { |report| report['fan'] }
  end

  private

  def normalize(item, source, since)
    raise FeedError, 'Invalid story object' unless item.is_a?(Hash)

    published = Time.iso8601(item.fetch('contentDate')).utc
    return nil if published.to_date < since || published > @now
    return nil unless item.dig('context', 'slug') == "teamid-#{source[0]}"

    slug = item['slug'].to_s
    raise FeedError, 'Invalid article slug' unless slug.match?(/\A[a-zA-Z0-9_-]+\z/)

    title = plain_text(item['headline'])
    title = plain_text(item['title']) if title.empty?
    raise FeedError, 'Missing headline' if title.empty?

    description = plain_text(item.dig('fields', 'description'))
    description = description[0, 197].sub(/\s+\S*\z/, '') + '...' if description.length > 200
    {
      'title' => title, 'published_at' => published.iso8601,
      'url' => "https://www.nhl.com/#{source[1]}/news/#{slug}",
      'summary' => description,
      'roster_news' => title.match?(ROSTER_HEADLINE) ||
        Array(item['tags']).any? { |tag| tag.is_a?(Hash) && tag['slug'] == 'transactions' }
    }
  rescue FeedError, KeyError, ArgumentError, TypeError => error
    raise FeedError, error.message
  end

  def plain_text(value)
    CGI.unescapeHTML(value.to_s).gsub(/<[^>]*>/, ' ').gsub(/\s+/, ' ').strip
  end

  def read_cache
    return {} unless File.exist?(@cache_path)

    value = JSON.parse(File.read(@cache_path))
    raise FeedError, 'Expected a team-keyed cache' unless value.is_a?(Hash)

    value
  rescue JSON::ParserError, FeedError => error
    warn "Offseason news cache ignored: #{error.message}"
    {}
  end

  def cached_report(value, news_url, since)
    return nil unless value.is_a?(Hash)
    raise FeedError, 'Invalid cached articles' unless value['articles'].is_a?(Array)

    checked = Time.iso8601(value.fetch('updated_at'))
    articles = value['articles'].select do |story|
      raise FeedError, 'Invalid cached story' unless story.is_a?(Hash) && story['title'].is_a?(String)

      published = Time.iso8601(story.fetch('published_at'))
      raise FeedError, 'Invalid cached article URL' unless story['url'].to_s.match?(/\A#{Regexp.escape(news_url)}\/[a-zA-Z0-9_-]+\z/)

      published.to_date >= since && published <= @now
    end
    return nil if articles.empty?

    { 'updated_at' => checked.utc.iso8601, 'articles' => articles }
  rescue FeedError, KeyError, ArgumentError, TypeError => error
    warn "Offseason news cache entry ignored: #{error.message}"
    nil
  end
end
