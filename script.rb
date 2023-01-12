#!/usr/bin/env ruby
# frozen_string_literal: true
# Function to get the team IDs from the NHL API https://statsapi.web.nhl.com/api/v1/teams
# Example response:
# {
    # "copyright" : "NHL and the NHL Shield are registered trademarks of the National Hockey League. NHL and NHL team marks are the property of the NHL and its teams. © NHL 2023. All Rights Reserved.",
    # "teams" : [ {
    #   "id" : 1,
    #   "name" : "New Jersey Devils",
    #   "link" : "/api/v1/teams/1",
    #   "venue" : {
    #     "name" : "Prudential Center",
    #     "link" : "/api/v1/venues/null",
    #     "city" : "Newark",
    #     "timeZone" : {
    #       "id" : "America/New_York",
    #       "offset" : -5,
    #       "tz" : "EST"
    #     }
    #   },
    #   "abbreviation" : "NJD",
    #   "teamName" : "Devils",
    #   "locationName" : "New Jersey",
    #   "firstYearOfPlay" : "1982",
    #   "division" : {
    #     "id" : 18,
    #     "name" : "Metropolitan",
    #     "nameShort" : "Metro",
    #     "link" : "/api/v1/divisions/18",
    #     "abbreviation" : "M"
    #   },
    #   "conference" : {
    #     "id" : 6,
    #     "name" : "Eastern",
    #     "link" : "/api/v1/conferences/6"
    #   },
    #   "franchise" : {
    #     "franchiseId" : 23,
    #     "teamName" : "Devils",
    #     "link" : "/api/v1/franchises/23"
    #   },
    #   "teamStats" : [ {
    #     "type" : {
    #       "displayName" : "statsSingleSeason",
    #       "gameType" : {
    #         "id" : "R",
    #         "description" : "Regular season",
    #         "postseason" : false
    #       }
    #     },
    #     "splits" : [ {
    #       "stat" : {
    #         "gamesPlayed" : 41,
    #         "wins" : 26,
    #         "losses" : 12,
    #         "ot" : 3,
    #         "pts" : 55,
    #         "ptPctg" : "67.1",
    #         "goalsPerGame" : 3.439,
    #         "goalsAgainstPerGame" : 2.634,
    #         "evGGARatio" : 1.4412,
    #         "powerPlayPercentage" : "20.0",
    #         "powerPlayGoals" : 26.0,
    #         "powerPlayGoalsAgainst" : 23.0,
    #         "powerPlayOpportunities" : 130.0,
    #         "penaltyKillPercentage" : "82.2",
    #         "shotsPerGame" : 34.561,
    #         "shotsAllowed" : 27.3171,
    #         "winScoreFirst" : 0.682,
    #         "winOppScoreFirst" : 0.579,
    #         "winLeadFirstPer" : 0.667,
    #         "winLeadSecondPer" : 0.95,
    #         "winOutshootOpp" : 0.567,
    #         "winOutshotByOpp" : 0.8,
    #         "faceOffsTaken" : 2395.0,
    #         "faceOffsWon" : 1218.0,
    #         "faceOffsLost" : 1177.0,
    #         "faceOffWinPercentage" : "50.9",
    #         "shootingPctg" : 10.0,
    #         "savePctg" : 0.904
    #       },
    #       "team" : {
    #         "id" : 1,
    #         "name" : "New Jersey Devils",
    #         "link" : "/api/v1/teams/1"
    #       }
    #     }, {
    #       "stat" : {
    #         "wins" : "4th",
    #         "losses" : "5th",
    #         "ot" : "20th",
    #         "pts" : "7th",
    #         "ptPctg" : "4th",
    #         "goalsPerGame" : "7th",
    #         "goalsAgainstPerGame" : "4th",
    #         "evGGARatio" : "3rd",
    #         "powerPlayPercentage" : "21st",
    #         "powerPlayGoals" : "21st",
    #         "powerPlayGoalsAgainst" : "6th",
    #         "powerPlayOpportunities" : "18th",
    #         "penaltyKillOpportunities" : "16th",
    #         "penaltyKillPercentage" : "7th",
    #         "shotsPerGame" : "4th",
    #         "shotsAllowed" : "2nd",
    #         "winScoreFirst" : "12th",
    #         "winOppScoreFirst" : "2nd",
    #         "winLeadFirstPer" : "22nd",
    #         "winLeadSecondPer" : "4th",
    #         "winOutshootOpp" : "14th",
    #         "winOutshotByOpp" : "14th",
    #         "faceOffsTaken" : "12th",
    #         "faceOffsWon" : "12th",
    #         "faceOffsLost" : "17th",
    #         "faceOffWinPercentage" : "12th",
    #         "savePctRank" : "14th",
    #         "shootingPctRank" : "19th"
    #       },
    #       "team" : {
    #         "id" : 1,
    #         "name" : "New Jersey Devils",
    #         "link" : "/api/v1/teams/1"
    #       }
    #     } ]
    #   } ],
    #   "shortName" : "New Jersey",
    #   "officialSiteUrl" : "http://www.newjerseydevils.com/",
    #   "franchiseId" : 23,
    #   "active" : true
    # },

require 'csv'
require 'httparty'

# Read in the fan and team names from csv file
fan_team_hash = {}
CSV.foreach('fan_team.csv', headers: true) do |row|
    fan_team_hash[row['fan']] = row['team']
end

# Function to get array of team ids from the https://statsapi.web.nhl.com/api/v1/teams endpoint using a fuzzy search against the results based on team names from the fan_team_hash
def get_team_ids(fan_team_hash)
    team_ids = []
    fan_team_hash.each do |fan, team|
        response = HTTParty.get('https://statsapi.web.nhl.com/api/v1/teams')
        response.parsed_response['teams'].each do |team|
            if team['name'].include? fan_team_hash[fan]
                team_ids.push(team['id'])
                #puts "Team ID: #{team['id']} for #{fan_team_hash[fan]}"
            end
        end
    end
    return team_ids
end

# Get stats for a team id
def get_team_stats(team_id)
    response = HTTParty.get('https://statsapi.web.nhl.com/api/v1/teams/' + team_id.to_s + '?expand=team.stats')
    response.parsed_response['teams'].each do |team|
        puts "Team Name: #{team['name']}"
        puts "Team ID: #{team['id']}"
        puts "Wins: #{team['teamStats'][0]['splits'][0]['stat']['wins']}"
        puts "Losses: #{team['teamStats'][0]['splits'][0]['stat']['losses']}"
        puts "Overtime Losses: #{team['teamStats'][0]['splits'][0]['stat']['ot']}"
        puts "Points: #{team['teamStats'][0]['splits'][0]['stat']['pts']}"
        puts "Point Percentage: #{team['teamStats'][0]['splits'][0]['stat']['ptPctg']}"
        puts " "
    end
end

# Get stats for each of the fan teams
def get_fan_team_stats(fan_team_hash)
    team_ids = get_team_ids(fan_team_hash)
    team_ids.each do |team_id|
        get_team_stats(team_id)
    end
end

#get_fan_team_stats(fan_team_hash)

# Get stats for each of the fan teams, and load into an array
def get_fan_team_stats_array(fan_team_hash)
    team_ids = get_team_ids(fan_team_hash)
    team_stats_array = []
    team_ids.each do |team_id|
        response = HTTParty.get('https://statsapi.web.nhl.com/api/v1/teams/' + team_id.to_s + '?expand=team.stats')
        response.parsed_response['teams'].each do |team|
            team_stats_array.push(team['teamStats'][0]['splits'][0]['stat'])
            team_stats_array.last['name'] = team['name']
            # Add fan name to the team stats hash
            fan_team_hash.each do |fan, team|
                if team_stats_array.last['name'].include? fan_team_hash[fan]
                    team_stats_array.last['fan'] = fan
                end
            end
        end
    end
    return team_stats_array
end

# Sort the array of fan team stats by wins
def sort_fan_team_stats_by_wins(fan_team_hash)
    team_stats_array = get_fan_team_stats_array(fan_team_hash)
    sorted_team_stats_array = team_stats_array.sort_by { |hsh| hsh['wins'] }.reverse
    return sorted_team_stats_array
end

# Print the sorted array of fan team stats by wins
def print_sorted_fan_team_stats_by_wins(fan_team_hash)
    sorted_team_stats_array = sort_fan_team_stats_by_wins(fan_team_hash)
    sorted_team_stats_array.each do |team|
        puts "Team Name: #{team['name']}"
        puts "Fan Name: #{team['fan']}"
        puts "Wins: #{team['wins']}"
        puts "Losses: #{team['losses']}"
        puts "Overtime Losses: #{team['ot']}"
        puts "Points: #{team['pts']}"
        puts "Point Percentage: #{team['ptPctg']}"
        puts " "
    end
end

# Output to file a nice HTML table of the sorted array of fan team stats by wins
def output_sorted_fan_team_stats_by_wins_to_file(fan_team_hash)
    sorted_team_stats_array = sort_fan_team_stats_by_wins(fan_team_hash)
    File.open("_site/index.html", "w") do |f|
        f.write("<html><head><title>Fan Team Stats</title></head><body><table border='1'>")
        f.write("<tr><th>Team Name</th><th>Fan Name</th><th>Wins</th><th>Losses</th><th>Overtime Losses</th><th>Points</th><th>Point Percentage</th></tr>")
        sorted_team_stats_array.each do |team|
            f.write("<tr><td>#{team['name']}</td><td>#{team['fan']}</td><td>#{team['wins']}</td><td>#{team['losses']}</td><td>#{team['ot']}</td><td>#{team['pts']}</td><td>#{team['ptPctg']}</td></tr>")
        end
        f.write("</table></body></html>")
    end
end

print_sorted_fan_team_stats_by_wins(fan_team_hash)
