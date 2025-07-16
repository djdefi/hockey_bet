require 'httparty'
require 'json'
require 'date'
require 'tzinfo'
require 'erb'
require_relative 'api_validator'

class PlayoffProcessor
  attr_reader :playoff_data, :playoff_rounds, :cup_odds, :fan_cup_odds, :is_playoff_time, :last_updated, :season_info
  attr_writer :season_info

  def initialize(fallback_path = 'spec/fixtures')
    @fallback_path = fallback_path
    @validator = ApiValidator.new
    @playoff_data = {}
    @playoff_rounds = []
    @cup_odds = {}
    @fan_cup_odds = {}
    @is_playoff_time = false
    @last_updated = nil
    @season_info = {}
  end

  # Main process method to generate playoffs HTML
  def process(output_path, manager_team_map = {})
    # Fetch and process playoff data
    success = fetch_playoff_data
    
    # Determine season information from playoff data if not already set
    if @season_info.empty?
      @season_info = determine_season_info_from_playoffs
    end
    
    # Calculate fan cup odds if we have manager team mapping
    unless manager_team_map.empty?
      calculate_fan_cup_odds(manager_team_map)
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
    # Try the new playoffs/now endpoint first
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
      else
        process_playoff_data_new_format
      end

      calculate_cup_odds
      return true
    end

    false
  end

  # Determine season information from playoff data
  def determine_season_info_from_playoffs
    season_info = {
      season: 'Unknown',
      display_season: 'Unknown Season',
      status: 'Unknown',
      status_description: 'Season status unclear'
    }

    # Try to extract season from playoff data
    if @playoff_data && @playoff_data['season']
      season_number = @playoff_data['season'].to_s
      if season_number.length == 8
        # Format: 20242025 -> "2024-25"
        start_year = season_number[0..3]
        end_year = season_number[4..7][2..3]
        season_info[:season] = season_number
        season_info[:display_season] = "#{start_year}-#{end_year} NHL Playoffs"
      end
    end

    # Determine current playoff status
    current_date = Date.today
    current_month = current_date.month

    if @is_playoff_time && !@playoff_rounds.empty?
      season_info[:status] = 'Active Playoffs'
      season_info[:status_description] = 'NHL Playoffs currently in progress'
    elsif is_near_playoff_time?
      season_info[:status] = 'Approaching Playoffs'
      season_info[:status_description] = 'Playoff matchups will be available soon'
    elsif current_month >= 7 && current_month <= 9
      season_info[:status] = 'Offseason'
      season_info[:status_description] = 'NHL Offseason - showing previous playoff results'
      season_info[:warning] = 'Displaying previous season playoff results.'
    else
      season_info[:status] = 'Regular Season'
      season_info[:status_description] = 'Regular season in progress - playoffs upcoming'
    end

    season_info
  end

  # Check if we're close to playoff time (April-June)
  def is_near_playoff_time?
    current_month = Date.today.month
    [4, 5, 6].include?(current_month)
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

    # In a real implementation, this would use an algorithm based on
    # team strength, current playoff position, etc.
    # For now, we'll use a simple approach based on current playoff position

    @cup_odds = {}

    if @playoff_data["rounds"] && !@playoff_data["rounds"].empty?
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

  # Determine if we have valid playoff data
  def valid_playoff_data?(data)
    @validator.validate_playoffs_response(data)
  end

  private

  # Render the playoffs template
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
              #{pr_preview && pr_number ? "<div class='flash flash-warn'>🚧 PR ##{pr_number} Preview Environment</div>" : ""}
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
