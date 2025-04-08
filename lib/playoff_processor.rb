require 'httparty'
require 'json'
require 'date'
require 'tzinfo'

class PlayoffProcessor
  attr_reader :playoff_data, :playoff_rounds, :cup_odds, :fan_cup_odds, :is_playoff_time

  def initialize(fallback_path = 'spec/fixtures')
    @fallback_path = fallback_path
    @playoff_data = {}
    @playoff_rounds = []
    @cup_odds = {}
    @fan_cup_odds = {}
    @is_playoff_time = false
  end

  # Fetch playoff data from NHL API
  def fetch_playoff_data
    url = "https://api-web.nhle.com/v1/standings/playoffs"
    response = HTTParty.get(url)
    
    if response.code == 200
      data = JSON.parse(response.body)
      if valid_playoff_data?(data)
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
    begin
      if File.exist?("#{@fallback_path}/playoffs.json")
        fallback = JSON.parse(File.read("#{@fallback_path}/playoffs.json"))
        if valid_playoff_data?(fallback)
          @playoff_data = fallback
          @is_playoff_time = true
          process_playoff_data
          calculate_cup_odds
          return true
        end
      end
    rescue => e
      puts "Error loading fallback playoff data: #{e.message}"
    end
    
    false
  end

  # Check if we're close to playoff time (April-June)
  def is_near_playoff_time?
    current_month = Date.today.month
    [4, 5, 6].include?(current_month)
  end

  # Process playoff data into structured rounds for display
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

  # Format a team for display in playoff bracket
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

  # Format a playoff game for display
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
    data && data["rounds"] && !data["rounds"].empty?
  end
end
