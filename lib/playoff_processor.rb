require 'httparty'
require 'json'
require 'date'
require 'tzinfo'
require 'erb'
require_relative 'api_validator'

class PlayoffProcessor
  attr_reader :playoff_data, :playoff_rounds, :cup_odds, :fan_cup_odds, :is_playoff_time, :last_updated, :bracket_logo, :fan_status, :manager_team_map

  def initialize(fallback_path = 'spec/fixtures')
    @fallback_path = fallback_path
    @validator = ApiValidator.new
    @playoff_data = {}
    @playoff_rounds = []
    @cup_odds = {}
    @fan_cup_odds = {}
    @is_playoff_time = false
    @last_updated = nil
    @bracket_logo = nil
    @fan_status = {}
    @manager_team_map = {}
  end

  # Main process method to generate playoffs HTML
  def process(output_path, manager_team_map = {})
    # Fetch and process playoff data
    success = fetch_playoff_data

    @manager_team_map = manager_team_map || {}

    # Calculate fan cup odds if we have manager team mapping
    unless manager_team_map.empty?
      calculate_fan_cup_odds(manager_team_map)
      compute_fan_status(manager_team_map)
    end
    
    # Update timestamp
    @last_updated = Time.now.strftime("%Y-%m-%d %H:%M:%S UTC")
    
    # Ensure the output directory exists
    output_dir = File.dirname(output_path)
    Dir.mkdir(output_dir) unless Dir.exist?(output_dir)

    # Render the template and write to file
    html_content = render_template
    File.write(output_path, html_content)
    
    success
  end

  # Fetch playoff data from NHL API
  def fetch_playoff_data
    # Try the current playoff-bracket endpoint first — the legacy
    # /v1/playoffs/now and /v1/standings/playoffs endpoints were retired
    # by the NHL in 2024 and now return 404.
    bracket_url = "https://api-web.nhle.com/v1/playoff-bracket/#{bracket_year}"
    bracket_response = HTTParty.get(bracket_url)

    if bracket_response.code == 200
      data = JSON.parse(bracket_response.body)
      if @validator.validate_playoffs_response(data)
        @playoff_data = data
        series_list = data["series"]
        has_series = series_list.is_a?(Array) && !series_list.empty?
        @is_playoff_time = has_series
        process_playoff_data_bracket_format
        calculate_cup_odds if has_series
        return true
      end
    end

    # Try the legacy playoffs/now endpoint (kept for backwards compatibility
    # with fixtures and any future re-introduction of the endpoint).
    now_url = "https://api-web.nhle.com/v1/playoffs/now"
    now_response = HTTParty.get(now_url)

    if now_response.code == 200
      data = JSON.parse(now_response.body)
      if @validator.validate_playoffs_response(data)
        @playoff_data = data
        @is_playoff_time = true
        process_playoff_data_new_format
        calculate_cup_odds
        return true
      end
    end

    # Fall back to the standings/playoffs endpoint if the new one fails
    standings_url = "https://api-web.nhle.com/v1/standings/playoffs"
    standings_response = HTTParty.get(standings_url)

    if standings_response.code == 200
      data = JSON.parse(standings_response.body)
      if @validator.validate_playoffs_response(data)
        @playoff_data = data
        @is_playoff_time = true
        process_playoff_data
        calculate_cup_odds
        return true
      end
    end

    # If we don't have valid playoff data, check if we're close to playoff time
    @is_playoff_time = is_near_playoff_time?

    # Use fallback data for testing if needed
    fallback = @validator.handle_api_failure('playoffs', "#{@fallback_path}/playoffs.json")

    if !fallback.empty? && @validator.validate_playoffs_response(fallback)
      @playoff_data = fallback
      @is_playoff_time = true

      # Determine which format to process based on the structure
      if fallback.key?('rounds')
        process_playoff_data
      elsif fallback.key?('playoffRounds') || fallback.key?('currentRound')
        process_playoff_data_new_format
      else
        process_playoff_data_bracket_format
      end

      calculate_cup_odds
      return true
    end

    false
  end

  # NHL season-end year used by the playoff-bracket endpoint.
  # The 2025-26 regular season runs Oct 2025 - Apr 2026, with playoffs ending
  # in June 2026, so the bracket for that season lives at /playoff-bracket/2026.
  # We treat July as the cutover month (offseason).
  def bracket_year
    today = Date.today
    today.month >= 7 ? today.year + 1 : today.year
  end

  # Check if we're close to playoff time (April-June)
  def is_near_playoff_time?
    current_month = Date.today.month
    [4, 5, 6].include?(current_month)
  end

  # Process playoff data for the playoff-bracket/{year} endpoint format.
  # This endpoint returns a flat array of series across all rounds; we group
  # by seriesAbbrev (R1/R2/CF/SCF) — the canonical round identifier — and
  # fall back to playoffRound for older bracket payloads that omit it.
  def process_playoff_data_bracket_format
    return unless @playoff_data["series"].is_a?(Array)

    @bracket_logo = @playoff_data["bracketLogo"]

    grouped = @playoff_data["series"].group_by do |s|
      s["seriesAbbrev"] || "R#{s['playoffRound']}"
    end

    @playoff_rounds = grouped.sort_by { |key, _| BRACKET_ROUND_ORDER[key] || 99 }.map do |key, series_in_round|
      round_name = BRACKET_ROUND_NAMES[key] || series_in_round.first["seriesTitle"] || key

      {
        name: round_name,
        round_key: key,
        round_number: series_in_round.first["playoffRound"].to_i,
        series: series_in_round.map { |series| build_bracket_series(series) }
      }
    end
  end

  # Build a normalized series hash from one bracket-format entry.
  def build_bracket_series(series)
    top_team = series["topSeedTeam"]
    bottom_team = series["bottomSeedTeam"]
    top_wins = series["topSeedWins"].to_i
    bottom_wins = series["bottomSeedWins"].to_i
    winner_id = series["winningTeamId"]
    is_tbd = top_team.nil? || bottom_team.nil?

    home_payload = format_playoff_team_bracket_format(top_team, series["topSeedRankAbbrev"])
    away_payload = format_playoff_team_bracket_format(bottom_team, series["bottomSeedRankAbbrev"])

    winner_abbrev =
      if winner_id && top_team && top_team["id"] == winner_id then top_team["abbrev"]
      elsif winner_id && bottom_team && bottom_team["id"] == winner_id then bottom_team["abbrev"]
      end

    eliminated_abbrev =
      if winner_id && top_team && top_team["id"] != winner_id then top_team["abbrev"]
      elsif winner_id && bottom_team && bottom_team["id"] != winner_id then bottom_team["abbrev"]
      end

    {
      id: series["seriesLetter"] || series["seriesAbbrev"],
      series_letter: series["seriesLetter"],
      series_abbrev: series["seriesAbbrev"],
      status: bracket_series_status(series, top_wins, bottom_wins),
      home_team: home_payload,
      away_team: away_payload,
      home_wins: top_wins,
      away_wins: bottom_wins,
      winner_abbrev: winner_abbrev,
      eliminated_abbrev: eliminated_abbrev,
      is_tbd: is_tbd,
      is_upset: bracket_series_upset?(series),
      games: []
    }
  end

  # Detect when the lower-seeded team is leading or has won the series.
  def bracket_series_upset?(series)
    top_rank = series["topSeedRank"].to_i
    bottom_rank = series["bottomSeedRank"].to_i
    return false if top_rank.zero? || bottom_rank.zero?

    top_wins = series["topSeedWins"].to_i
    bottom_wins = series["bottomSeedWins"].to_i

    # Higher seed-rank number = lower seed. Flag when the lower seed leads
    # outright, or has clinched the upset.
    if bottom_rank > top_rank
      bottom_wins > top_wins
    elsif top_rank > bottom_rank
      top_wins > bottom_wins
    else
      false
    end
  end

  BRACKET_ROUND_NAMES = {
    "R1" => "1st Round",
    "R2" => "2nd Round",
    "CF" => "Conference Finals",
    "SCF" => "Stanley Cup Final"
  }.freeze

  BRACKET_ROUND_ORDER = { "R1" => 1, "R2" => 2, "CF" => 3, "SCF" => 4 }.freeze

  # Build a human-readable status for a bracket-format series, since the
  # endpoint doesn't include the legacy "seriesStatus" string.
  def bracket_series_status(series, top_wins, bottom_wins)
    return "" if series["topSeedTeam"].nil? || series["bottomSeedTeam"].nil?

    if series["winningTeamId"]
      winner_id = series["winningTeamId"]
      winner = [series["topSeedTeam"], series["bottomSeedTeam"]].find { |t| t && t["id"] == winner_id }
      winner_abbrev = winner ? winner["abbrev"] : ""
      "#{winner_abbrev} wins #{[top_wins, bottom_wins].max}-#{[top_wins, bottom_wins].min}"
    else
      leader = top_wins > bottom_wins ? series["topSeedTeam"] : series["bottomSeedTeam"]
      if top_wins.zero? && bottom_wins.zero?
        "Series not started"
      elsif top_wins == bottom_wins
        "Series tied #{top_wins}-#{bottom_wins}"
      else
        "#{leader["abbrev"]} leads #{[top_wins, bottom_wins].max}-#{[top_wins, bottom_wins].min}"
      end
    end
  end

  # Format a team for display from the playoff-bracket endpoint.
  # Falls back to a TBD placeholder so later-round series (which omit teams
  # until they're determined) still render in the bracket.
  def format_playoff_team_bracket_format(team, seed_abbrev = nil)
    return { name: "TBD", short_name: "TBD", abbrev: "TBD", seed: nil, record: "TBD" } unless team

    full_name = (team["name"] && team["name"]["default"]) || team["abbrev"]
    short_name = (team["commonName"] && team["commonName"]["default"]) || full_name

    {
      name: full_name,
      short_name: short_name,
      abbrev: team["abbrev"],
      logo: team["logo"],
      seed: seed_abbrev || team["seed"],
      record: "TBD"
    }
  end

  # Process playoff data into structured rounds for display (for standings/playoffs endpoint)
  def process_playoff_data
    return unless @playoff_data["rounds"]

    @playoff_rounds = @playoff_data["rounds"].map do |round|
      {
        name: round["names"]["name"],
        series: round["series"].map do |series|
          home_team = series["matchupTeams"].find { |t| t["homeRoad"] == "H" }
          away_team = series["matchupTeams"].find { |t| t["homeRoad"] == "R" }

          {
            id: series["seriesCode"],
            status: series["seriesStatus"],
            home_team: format_playoff_team(home_team),
            away_team: format_playoff_team(away_team),
            home_wins: home_team ? home_team["seriesWins"] : 0,
            away_wins: away_team ? away_team["seriesWins"] : 0,
            games: series["games"].map { |g| format_playoff_game(g) } || []
          }
        end
      }
    end
  end

  # Process playoff data for the new playoffs/now endpoint format
  def process_playoff_data_new_format
    return unless @playoff_data["playoffRounds"]

    @playoff_rounds = @playoff_data["playoffRounds"].map do |round|
      {
        name: round["names"] ? round["names"]["name"] : "Round #{round['round']}",
        series: round["series"].map do |series|
          # The structure is slightly different in this endpoint
          home_team = series["matchupTeams"].find { |t| t["homeIndicator"] }
          away_team = series["matchupTeams"].find { |t| !t["homeIndicator"] }

          {
            id: series["seriesCode"],
            status: series["seriesStatus"],
            home_team: format_playoff_team_new_format(home_team),
            away_team: format_playoff_team_new_format(away_team),
            home_wins: home_team ? home_team["seriesWins"] : 0,
            away_wins: away_team ? away_team["seriesWins"] : 0,
            games: series["games"] ? series["games"].map { |g| format_playoff_game_new_format(g) } : []
          }
        end
      }
    end
  end

  # Format a team for display in playoff bracket (for standings/playoffs endpoint)
  def format_playoff_team(team)
    return { name: "TBD", abbrev: "TBD", seed: "TBD" } unless team

    {
      name: team["teamName"]["default"],
      abbrev: team["teamAbbrev"]["default"],
      logo: team["teamLogo"],
      seed: team["seed"],
      record: "#{team["wins"]}-#{team["losses"]}-#{team["otLosses"]}"
    }
  end

  # Format a team for display in playoff bracket (for playoffs/now endpoint)
  def format_playoff_team_new_format(team)
    return { name: "TBD", abbrev: "TBD", seed: "TBD" } unless team

    {
      name: team["teamName"] ? team["teamName"]["default"] : team["name"]["default"],
      abbrev: team["teamAbbrev"] ? team["teamAbbrev"]["default"] : team["abbrev"]["default"],
      logo: team["logo"] || team["teamLogo"],
      seed: team["seed"],
      record: team["wins"] ? "#{team["wins"]}-#{team["losses"]}-#{team["otLosses"]}" : "TBD"
    }
  end

  # Format a playoff game for display (for standings/playoffs endpoint)
  def format_playoff_game(game)
    return {} unless game

    {
      number: game["gameNumber"],
      status: game["gameState"],
      start_time: game["startTimeUTC"],
      home_score: game["homeTeam"]["score"],
      away_score: game["awayTeam"]["score"]
    }
  end

  # Format a playoff game for display (for playoffs/now endpoint)
  def format_playoff_game_new_format(game)
    return {} unless game

    {
      number: game["gameNumber"] || game["seriesGameNumber"],
      status: game["gameState"] || game["gameStatus"],
      start_time: game["startTimeUTC"],
      home_score: game["homeTeam"] ? game["homeTeam"]["score"] : 0,
      away_score: game["awayTeam"] ? game["awayTeam"]["score"] : 0
    }
  end

  # Calculate cup odds for each team
  def calculate_cup_odds
    return unless @is_playoff_time

    @cup_odds = {}

    if @playoff_data["series"].is_a?(Array) && !@playoff_data["series"].empty?
      # Bracket format: aggregate per-team progress across all series.
      # A team's "round reached" is the highest playoffRound a series featuring
      # them appears in, plus 1 if they won that series.
      playoff_teams = {}

      @playoff_data["series"].each do |series|
        abbrev_round = BRACKET_ROUND_ORDER[series["seriesAbbrev"]]
        round_number = abbrev_round || series["playoffRound"].to_i
        winner_id = series["winningTeamId"]

        [
          [series["topSeedTeam"], series["topSeedWins"].to_i],
          [series["bottomSeedTeam"], series["bottomSeedWins"].to_i]
        ].each do |team, wins|
          next unless team && team["abbrev"]

          abbrev = team["abbrev"]
          # Reaching a round is worth one "round point"; winning that round
          # bumps the team up another tier.
          round_reached = round_number + (winner_id && team["id"] == winner_id ? 1 : 0)
          existing = playoff_teams[abbrev]
          if existing.nil? || round_reached > existing[:round] ||
             (round_reached == existing[:round] && wins > existing[:wins])
            playoff_teams[abbrev] = { round: round_reached, wins: wins }
          end
        end
      end

      total_points = playoff_teams.sum { |_, d| (d[:round] * 10) + (d[:wins] * 3) }
      if total_points.positive?
        playoff_teams.each do |abbrev, data|
          points = (data[:round] * 10) + (data[:wins] * 3)
          @cup_odds[abbrev] = ((points.to_f / total_points) * 100).round(1)
        end
      end
    elsif @playoff_data["rounds"] && !@playoff_data["rounds"].empty?
      # Get teams still in the playoffs
      playoff_teams = {}

      @playoff_data["rounds"].each do |round|
        round["series"].each do |series|
          series["matchupTeams"].each do |team|
            next unless team["teamAbbrev"] && team["teamAbbrev"]["default"]

            team_abbrev = team["teamAbbrev"]["default"]
            round_number = round["roundNumber"].to_i
            team_wins = team["seriesWins"].to_i

            # Teams in later rounds or with more wins have better odds
            playoff_teams[team_abbrev] = {
              round: round_number,
              wins: team_wins
            }
          end
        end
      end

      # Calculate odds based on round and series wins
      total_points = playoff_teams.sum do |_, data|
        (data[:round] * 10) + (data[:wins] * 3)
      end

      playoff_teams.each do |abbrev, data|
        points = (data[:round] * 10) + (data[:wins] * 3)
        @cup_odds[abbrev] = ((points.to_f / total_points) * 100).round(1)
      end
    else
      # Fallback to regular season standings if playoffs haven't started
      # In this case, we'd calculate based on points percentage and other factors
      # This would need regular season standings data to work correctly
    end
  end

  # Calculate cup odds for fans based on their team selection
  def calculate_fan_cup_odds(manager_team_map)
    return {} unless @is_playoff_time && !@cup_odds.empty?

    fan_odds = {}

    # Group teams by fan
    fans_teams = {}
    manager_team_map.each do |team_abbrev, fan|
      next if fan == "N/A"
      fans_teams[fan] ||= []
      fans_teams[fan] << team_abbrev
    end

    # Calculate odds for each fan
    fans_teams.each do |fan, teams|
      fan_odds[fan] = teams.sum { |team| @cup_odds[team] || 0 }.round(1)
    end

    # Sort by odds (descending) and return
    @fan_cup_odds = fan_odds.sort_by { |_, odds| -odds }.to_h
  end

  # Compute per-fan status across all picked teams using the bracket data.
  # Returns a hash of `{fan => {teams: [...], status: :alive|:eliminated|:champion,
  #   round_reached, round_label, opponent, series_status, tagline}}`.
  def compute_fan_status(manager_team_map)
    @fan_status = {}
    return @fan_status unless @is_playoff_time && @playoff_rounds && !@playoff_rounds.empty?

    # Group teams by fan
    fans_teams = {}
    manager_team_map.each do |team_abbrev, fan|
      next if fan.nil? || fan == "N/A"
      fans_teams[fan] ||= []
      fans_teams[fan] << team_abbrev
    end

    # Build a flat lookup of every team's bracket history across rounds.
    team_history = build_team_history

    fans_teams.each do |fan, team_abbrevs|
      team_summaries = team_abbrevs.map do |abbrev|
        history = team_history[abbrev] || { round_reached: 0, round_label: nil, status: :not_in_playoffs, name: abbrev, logo: nil, opponent: nil, series_status: nil, last_round_key: nil }
        history.merge(abbrev: abbrev)
      end

      # Pick the best-positioned team to represent the fan's overall status.
      primary = team_summaries.max_by { |t| t[:round_reached] || 0 }
      next if primary.nil?

      status = primary[:status] || :alive
      tagline = fan_tagline_for(status, primary)

      @fan_status[fan] = {
        teams: team_summaries,
        primary_team: primary,
        status: status,
        round_reached: primary[:round_reached] || 0,
        round_label: primary[:round_label],
        opponent: primary[:opponent],
        series_status: primary[:series_status],
        tagline: tagline,
        cup_odds: @fan_cup_odds[fan] || 0
      }
    end

    @fan_status
  end

  # Friendly label for the current/most-advanced active round (for the
  # standings hero banner). Returns nil when playoffs aren't active.
  def current_round_label
    return nil unless @is_playoff_time && @playoff_rounds && !@playoff_rounds.empty?

    # Find the most-advanced round that still has an undecided series.
    active = @playoff_rounds.reverse.find do |round|
      round[:series].any? { |s| !s[:is_tbd] && s[:winner_abbrev].nil? }
    end
    (active || @playoff_rounds.last)[:name]
  end

  # Number of fans who still have at least one team alive.
  def fans_alive_count
    return 0 if @fan_status.nil? || @fan_status.empty?
    @fan_status.count { |_, info| %i[alive champion].include?(info[:status]) }
  end

  # Determine if we have valid playoff data
  def valid_playoff_data?(data)
    @validator.validate_playoffs_response(data)
  end

  private

  # Build a flat lookup of every team that appears in the bracket, with
  # `{round_reached, round_label, status, opponent, series_status, last_round_key, name, logo}`.
  # round_reached uses BRACKET_ROUND_ORDER (R1=1, R2=2, CF=3, SCF=4) and is +1
  # for the eventual champion.
  def build_team_history
    history = {}
    return history unless @playoff_rounds

    @playoff_rounds.each do |round|
      round_index = BRACKET_ROUND_ORDER[round[:round_key]] || round[:round_number] || 0
      round[:series].each do |series|
        [series[:home_team], series[:away_team]].each do |team|
          next if team.nil? || team[:abbrev].nil? || team[:abbrev].empty?
          abbrev = team[:abbrev]
          opponent = (team == series[:home_team]) ? series[:away_team] : series[:home_team]

          # Each appearance means the team made it into this round.
          existing = history[abbrev] || { round_reached: 0, status: :alive }
          if round_index >= existing[:round_reached]
            history[abbrev] = {
              round_reached: round_index,
              round_label: round[:name],
              last_round_key: round[:round_key],
              name: team[:short_name] || team[:name] || abbrev,
              logo: team[:logo],
              opponent: opponent && !opponent[:is_tbd] ? (opponent[:short_name] || opponent[:name] || opponent[:abbrev]) : nil,
              series_status: series[:status],
              status: derive_team_status(series, abbrev, round[:round_key])
            }
          end
        end
      end
    end

    history
  end

  def derive_team_status(series, abbrev, round_key)
    if series[:winner_abbrev] == abbrev
      round_key == 'SCF' ? :champion : :alive
    elsif series[:eliminated_abbrev] == abbrev
      :eliminated
    else
      :alive
    end
  end

  def fan_tagline_for(status, primary)
    case status
    when :champion then "🏆 STANLEY CUP CHAMPION"
    when :eliminated then "💀 OUT — #{primary[:name]} fell in #{primary[:round_label]}"
    when :alive
      sstat = primary[:series_status].to_s
      if sstat.start_with?(primary[:abbrev]) && sstat.include?('wins')
        "🔥 #{primary[:name]} advance — on to the next round"
      elsif sstat.include?('leads')
        "🔥 Cooking — #{primary[:name]} #{sstat.split(' ', 2).last}"
      elsif sstat.include?('trails')
        "⚠️ On the brink — #{primary[:name]} #{sstat.split(' ', 2).last}"
      elsif sstat.include?('tied')
        "🤝 Knotted up — #{primary[:name]} #{sstat}"
      else
        "🏒 #{primary[:name]} alive in #{primary[:round_label]}"
      end
    else
      "🪑 No team in the bracket"
    end
  end

  private

  def render_template
    template_path = "lib/playoffs.html.erb"
    
    unless File.exist?(template_path)
      # Fallback to a basic template if the file doesn't exist
      return basic_playoffs_html
    end
    
    template = File.read(template_path)
    
    # Determine if we're running in PR preview mode
    pr_preview = ENV['PR_PREVIEW'] == 'true'
    pr_number = ENV.fetch('PR_NUMBER', nil)

    # Create a binding to access instance variables in ERB
    erb_binding = binding
    
    ERB.new(template).result(erb_binding)
  end

  # Basic fallback HTML if template is missing
  def basic_playoffs_html
    pr_preview = ENV['PR_PREVIEW'] == 'true'
    pr_number = ENV.fetch('PR_NUMBER', nil)
    
    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <title>NHL Playoffs</title>
          <link rel='stylesheet' href='https://unpkg.com/@primer/css@^20.2.4/dist/primer.css'>
      </head>
      <body>
          <div class="container-lg">
              #{pr_preview && pr_number ? "<div class='flash flash-warn'><iconify-icon icon=\"solar:danger-triangle-bold\" width=\"16\" height=\"16\"></iconify-icon> PR ##{pr_number} Preview Environment</div>" : ""}
              <h1>NHL Playoffs</h1>
              #{@is_playoff_time ? playoff_content_html : no_playoffs_html}
          </div>
      </body>
      </html>
    HTML
  end

  def playoff_content_html
    return "<p>Playoff data is being processed...</p>" if @playoff_rounds.empty?
    
    content = "<h2>Playoff Bracket</h2>"
    @playoff_rounds.each do |round|
      content += "<h3>#{round[:name]}</h3>"
      round[:series].each do |series|
        content += "<div style='border: 1px solid #ddd; margin: 10px; padding: 10px;'>"
        content += "<div>#{series[:home_team][:name]} (#{series[:home_wins]}) vs #{series[:away_team][:name]} (#{series[:away_wins]})</div>"
        content += "<div>Status: #{series[:status]}</div>" if series[:status]
        content += "</div>"
      end
    end
    content
  end

  def no_playoffs_html
    "<div style='text-align: center; padding: 2rem;'><h2>No Active Playoffs</h2><p>Check back during playoff season!</p></div>"
  end
end
