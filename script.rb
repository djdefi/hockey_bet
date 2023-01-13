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
    
    # function to write HTML footer
    def write_footer(f)
        f.write("</body></html>")
    end

    # function to write HTML header
    def write_header(f)
        f.write("<html><head><link href='https://unpkg.com/@primer/css@^20.2.4/dist/primer.css' rel='stylesheet' /><title>Hockey Bet Stats</title></head><body>")
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
    
    # Get stats for each of the fan teams, and load into an array
    def get_fan_team_stats_array(fan_team_hash)
        team_ids = get_team_ids(fan_team_hash)
        team_stats_array = []
        team_ids.each do |team_id|
            response = HTTParty.get('https://statsapi.web.nhl.com/api/v1/teams/' + team_id.to_s + '?expand=team.stats&expand=team.schedule.next')
            response.parsed_response['teams'].each do |team|
                team_stats_array.push(team['teamStats'][0]['splits'][0]['stat'])
                team_stats_array.last['name'] = team['name']
                # Add fan name to the team stats hash
                fan_team_hash.each do |fan, team|
                    if team_stats_array.last['name'].include? fan_team_hash[fan]
                        team_stats_array.last['fan'] = fan
                    end
                end
                # Add next game date and opponent to the team stats hash
                team_stats_array.last['nextGameDate'] = team['nextGameSchedule']['dates'][0]['date']
                team_stats_array.last['nextGameOpponent'] = team['nextGameSchedule']['dates'][0]['games'][0]['teams']['away']['team']['name']
                # If the next game is against the fan's team, then change the opponent to the home team
                if team_stats_array.last['nextGameOpponent'].include? fan_team_hash[team_stats_array.last['fan']]
                    team_stats_array.last['nextGameOpponent'] = team['nextGameSchedule']['dates'][0]['games'][0]['teams']['home']['team']['name']
                end

                # Add team's leagueRank from https://statsapi.web.nhl.com/api/v1/standings to the team stats hash for the team
                response = HTTParty.get('https://statsapi.web.nhl.com/api/v1/standings')
                response.parsed_response['records'].each do |record|
                    record['teamRecords'].each do |team_record|
                        if team_record['team']['name'].include? team_stats_array.last['name']
                            team_stats_array.last['leagueRank'] = team_record['leagueRank']
                        end
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

    # Sort the array of fan team stats by league rank
    def sort_fan_team_stats_by_league_rank(fan_team_hash)
        team_stats_array = get_fan_team_stats_array(fan_team_hash)
        sorted_team_stats_array = team_stats_array.sort_by { |hsh| hsh['leagueRank'].to_i }
        return sorted_team_stats_array
    end
    
    # Print the sorted array of fan team stats by league rank
    def print_sorted_fan_team_stats_by_league_rank(fan_team_hash)
        sorted_team_stats_array = sort_fan_team_stats_by_league_rank(fan_team_hash)
        sorted_team_stats_array.each do |team|
            puts "Team Name: #{team['name']}"
            puts "Fan Name: #{team['fan']}"
            puts "Wins: #{team['wins']}"
            puts "Losses: #{team['losses']}"
            puts "Points: #{team['pts']}"
            puts "Point Percentage: #{team['ptPctg']}"
            puts "Goals per Game: #{team['goalsPerGame']}"
            puts "Goals Against per Game: #{team['goalsAgainstPerGame']}"
            puts "Next Game Date: #{team['nextGameDate']}"
            puts "Next Game Opponent: #{team['nextGameOpponent']}"
            puts "League Rank: #{team['leagueRank']}"
            puts " "
        end
    end

    # Function to get a hash of the name, description html object, and imageUrl for id 1 of https://records.nhl.com/site/api/trophy for use in the output html
    def get_trophy_info
        trophy_info = {}
        response = HTTParty.get('https://records.nhl.com/site/api/trophy')
        response.parsed_response['data'].each do |trophy|
            if trophy['id'] == 1
                trophy_info['name'] = trophy['name']
                trophy_info['description'] = trophy['description']
                trophy_info['imageUrl'] = trophy['imageUrl']
            end
        end
        return trophy_info
    end
    
    # Output to file a primer css styled HTML table of the sorted array of fan team stats by league rank
    def output_sorted_fan_team_stats_by_league_rank(fan_team_hash)
        sorted_team_stats_array = sort_fan_team_stats_by_league_rank(fan_team_hash)
        trophy_info = get_trophy_info
        File.open("_site/index.html", "w") do |f|
            f.write("<!DOCTYPE html>
    <html>
    <head>
    <title>NHL Standings</title>
    <link rel='stylesheet' href='https://unpkg.com/@primer/css@^20.2.4/dist/primer.css'>
    </head>
    <body class='m-2'>
    <h1 class='color-fg-success'>Hockey Team Standings</h1>
      <table>
        <thead>
                <th scope='col' class='p-2 border'>Team Name</th>
                <th scope='col' class='p-2 border'>Fan Name</th>
                <th scope='col' class='p-2 border'>Wins</th>
                <th scope='col' class='p-2 border'>Losses</th>
                <th scope='col' class='p-2 border'>Points</th>
                <th scope='col' class='p-2 border'>Point Percentage</th>
                <th scope='col' class='p-2 border'>Goals per Game</th>
                <th scope='col' class='p-2 border'>Goals Against per Game</th>
                <th scope='col' class='p-2 border'>League Rank</th>
                <th scope='col' class='p-2 border'>Next Game Date</th>
                <th scope='col' class='p-2 border'>Next Game Opponent</th>
        </thead>
        <tbody>")
            sorted_team_stats_array.each do |team|
                f.write("<tr>
                    <td class='p-2 border'>#{team['name']}</td>
                    <td class='p-2 border'>#{team['fan']}</td>
                    <td class='p-2 border'>#{team['wins']}</td>
                    <td class='p-2 border'>#{team['losses']}</td>
                    <td class='p-2 border'>#{team['pts']}</td>
                    <td class='p-2 border'>#{team['ptPctg']}</td>
                    <td class='p-2 border'>#{team['goalsPerGame']}</td>
                    <td class='p-2 border'>#{team['goalsAgainstPerGame']}</td>
                    <td class='p-2 border'>#{team['leagueRank']}</td>
                    <td class='p-2 border'>#{team['nextGameDate']}</td>
                    <td class='p-2 border'>#{team['nextGameOpponent']}</td>
                </tr>")
            end
            f.write("</tbody>
        </table>
        <div class='border-top border-bottom border-gray-light mt-3 pt-3'>
        <h2 class='color-fg-success'>#{trophy_info['name']}</h2>
        <img src='#{trophy_info['imageUrl']}' alt='#{trophy_info['name']}' style='width: 200px;'>
        <p class='color-fg-muted'>#{trophy_info['description']}</p>
        </div>
    </body>
    </html>")
        end
    end
   
    print_sorted_fan_team_stats_by_league_rank(fan_team_hash)
    output_sorted_fan_team_stats_by_league_rank(fan_team_hash)
    
    if File.file?("_site/index.html")
        puts "File created at: #{File.absolute_path("_site/index.html")}"
    end
