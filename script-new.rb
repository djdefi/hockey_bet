require 'httparty'
require 'json'
require 'csv'
require 'erb'

# Fetch Team Information
def fetch_team_info
  url = "https://api-web.nhle.com/v1/standings/now"
  response = HTTParty.get(url)
  if response.code == 200
    JSON.parse(response.body)["standings"]
  else
    puts "Error fetching data: #{response.code}"
    []
  end
end

# Map Managers to Teams
def map_managers_to_teams(csv_file, teams)
  manager_team_map = {}
  CSV.foreach(csv_file, headers: true) do |row|
    manager = row['fan']
    fuzzy_team_name = row['team'].strip.downcase
    matched_team = teams.find { |team| team['teamName']['default'].downcase.include?(fuzzy_team_name) }
    manager_team_map[matched_team ? matched_team['teamName']['default'] : "Team Not Found"] = manager
  end
  manager_team_map
end

# Render ERB Template
def render_template(manager_team_map, teams)
  template = File.read("standings.html.erb")
  ERB.new(template).result(binding)
end

# Main Execution
teams = fetch_team_info

# Sort teams by wins and then by points
sorted_teams = teams.sort_by { |team| [-team['wins'], -team['points']] }

manager_team_map = map_managers_to_teams("fan_team.csv", sorted_teams)

# Ensure the output directory exists
Dir.mkdir('_site') unless Dir.exist?('_site')
html_content = render_template(manager_team_map, sorted_teams)

# Output to file
File.write("_site/index.html", html_content)
