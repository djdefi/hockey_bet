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
    require 'time'
    require 'tzinfo'
    
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
        f.write("<html><head><link href='https://unpkg.com/@primer/css@20.8.3/dist/primer.css' rel='stylesheet' /><title>Hockey Bet Stats</title></head><body>")
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
                # Add next game date and opponent to the team stats hash - if there is no game scheduled, then set the date to "No Game Scheduled" and the opponent to "No Game Scheduled". 
                if team.key?('nextGameSchedule') && !team['nextGameSchedule'].nil? && team['nextGameSchedule'].key?('dates') && !team['nextGameSchedule']['dates'].empty?
                    team_stats_array.last['nextGameDate'] = team['nextGameSchedule']['dates'][0]['date']

                    team_stats_array.last['nextGameDate'] = team['nextGameSchedule']['dates'][0]['date']
                    team_stats_array.last['nextGameOpponent'] = team['nextGameSchedule']['dates'][0]['games'][0]['teams']['away']['team']['name']
                    # If the next game is against the fan's team, then change the opponent to the home team
                    if team_stats_array.last['nextGameOpponent'].include? fan_team_hash[team_stats_array.last['fan']]
                        team_stats_array.last['nextGameOpponent'] = team['nextGameSchedule']['dates'][0]['games'][0]['teams']['home']['team']['name']
                    end
                else
                    team_stats_array.last['nextGameDate'] = "No Game Scheduled"
                    team_stats_array.last['nextGameOpponent'] = "No Game Scheduled"
                end
                # Add team's leagueRank, conference name, conference rank, division name, division rank, wildcard rank, streakCode from https://statsapi.web.nhl.com/api/v1/standings to the team stats hash for the team
                response = HTTParty.get('https://statsapi.web.nhl.com/api/v1/standings')
                response.parsed_response['records'].each do |record|
                    if record['teamRecords'].any? { |h| h['team']['id'] == team_id }
                        team_stats_array.last['leagueRank'] = record['teamRecords'].find { |h| h['team']['id'] == team_id }['leagueRank']
                        #team_stats_array.last['conferenceName'] = record['conference']['name']
                        team_stats_array.last['conferenceRank'] = record['teamRecords'].find { |h| h['team']['id'] == team_id }['conferenceRank']
                        #team_stats_array.last['divisionName'] = record['division']['name']
                        team_stats_array.last['divisionRank'] = record['teamRecords'].find { |h| h['team']['id'] == team_id }['divisionRank']
                        team_stats_array.last['wildCardRank'] = record['teamRecords'].find { |h| h['team']['id'] == team_id }['wildCardRank']
                        team_stats_array.last['streakCode'] = record['teamRecords'].find { |h| h['team']['id'] == team_id }['streak']['streakCode']
                        # Lookup the conference name and division name from the team id separately and add to the team stats hash
                        response = HTTParty.get('https://statsapi.web.nhl.com/api/v1/teams/' + team_id.to_s + '?expand=team.stats')
                        team_stats_array.last['conferenceName'] = response.parsed_response['teams'][0]['conference']['name']
                        team_stats_array.last['divisionName'] = response.parsed_response['teams'][0]['division']['name']
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

    # Sort the array of fan team stats by league rank, conference rank, division rank, then wildcard rank
    def sort_fan_team_stats_by_league_rank(fan_team_hash)
        team_stats_array = get_fan_team_stats_array(fan_team_hash)
        sorted_team_stats_array = team_stats_array.sort_by { |hsh| hsh['leagueRank'].to_i }
        sorted_team_stats_array = sorted_team_stats_array.sort_by { |hsh| hsh['conferenceRank'].to_i }
        sorted_team_stats_array = sorted_team_stats_array.sort_by { |hsh| hsh['divisionRank'].to_i }
        sorted_team_stats_array = sorted_team_stats_array.sort_by { |hsh| hsh['wildCardRank'].to_i }
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
            puts "OT Losses: #{team['ot']}"
            puts "Points: #{team['pts']}"
            puts "Point Percentage: #{team['ptPctg']}"
            puts "Goals per Game: #{team['goalsPerGame']}"
            puts "Goals Against per Game: #{team['goalsAgainstPerGame']}"
            puts "Next Game Date: #{team['nextGameDate']}"
            puts "Next Game Opponent: #{team['nextGameOpponent']}"
            puts "League Rank: #{team['leagueRank']}"
            puts "Conference Name: #{team['conferenceName']}"
            puts "Conference Rank: #{team['conferenceRank']}"
            puts "Division Name: #{team['divisionName']}"
            puts "Division Rank: #{team['divisionRank']}"
            puts "Wildcard Rank: #{team['wildCardRank']}"
            puts "Streak: #{team['streakCode']}"
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

    # Function to get the playoff standings from https://statsapi.web.nhl.com/api/v1/tournaments/playoffs/?expand=round.series,schedule.game.seriesSummary&season=20222023
    # Example API response:
    # {"copyright"=>"NHL and the NHL Shield are registered trademarks of the National Hockey League. NHL and NHL team marks are the property of the NHL and its teams. © NHL 2023. All Rights Reserved.", "id"=>1, "name"=>"Playoffs", "season"=>"20222023", "defaultRound"=>2, "rounds"=>[{"number"=>1, "code"=>1, "names"=>{"name"=>"First Round", "shortName"=>"R1"}, "format"=>{"name"=>"BO7", "description"=>"Best of 7", "numberOfGames"=>7, "numberOfWins"=>4}, "series"=>[{"seriesNumber"=>1, "seriesCode"=>"A", "names"=>{"matchupName"=>"Bruins (1) vs. Panthers (WC2)", "matchupShortName"=>"BOS v FLA", "teamAbbreviationA"=>"BOS", "teamAbbreviationB"=>"FLA", "seriesSlug"=>"bruins-vs-panthers-series-a"}, "currentGame"=>{"seriesSummary"=>{"gamePk"=>2022030117, "gameNumber"=>7, "gameLabel"=>"Game 7", "necessary"=>true, "gameCode"=>117, "gameTime"=>"2023-04-30T22:30:00Z", "seriesStatus"=>"Panthers win 4-3", "seriesStatusShort"=>"FLA wins 4-3"}}, "conference"=>{"id"=>6, "name"=>"Eastern", "link"=>"/api/v1/conferences/6"}, "round"=>{"number"=>1}, "matchupTeams"=>[{"team"=>{"id"=>6, "name"=>"Boston Bruins", "link"=>"/api/v1/teams/6"}, "seed"=>{"type"=>"1", "rank"=>1, "isTop"=>true}, "seriesRecord"=>{"wins"=>3, "losses"=>4}}, {"team"=>{"id"=>13, "name"=>"Florida Panthers", "link"=>"/api/v1/teams/13"}, "seed"=>{"type"=>"WC2", "rank"=>4, "isTop"=>false}, "seriesRecord"=>{"wins"=>4, "losses"=>3}}]}, {"seriesNumber"=>2, "seriesCode"=>"B", "names"=>{"matchupName"=>"Maple Leafs (2) vs. Lightning (3)", "matchupShortName"=>"TOR v TBL", "teamAbbreviationA"=>"TOR", "teamAbbreviationB"=>"TBL", "seriesSlug"=>"maple-leafs-vs-lightning-series-b"}, "currentGame"=>{"seriesSummary"=>{"gamePk"=>2022030126, "gameNumber"=>6, "gameLabel"=>"Game 6", "necessary"=>true, "gameCode"=>126, "gameTime"=>"2023-04-29T23:00:00Z", "seriesStatus"=>"Maple Leafs win 4-2", "seriesStatusShort"=>"TOR wins 4-2"}}, "conference"=>{"id"=>6, "name"=>"Eastern", "link"=>"/api/v1/conferences/6"}, "round"=>{"number"=>1}, "matchupTeams"=>[{"team"=>{"id"=>10, "name"=>"Toronto Maple Leafs", "link"=>"/api/v1/teams/10"}, "seed"=>{"type"=>"2", "rank"=>2, "isTop"=>true}, "seriesRecord"=>{"wins"=>4, "losses"=>2}}, {"team"=>{"id"=>14, "name"=>"Tampa Bay Lightning", "link"=>"/api/v1/teams/14"}, "seed"=>{"type"=>"3", "rank"=>3, "isTop"=>false}, "seriesRecord"=>{"wins"=>2, "losses"=>4}}]}, {"seriesNumber"=>3, "seriesCode"=>"C", "names"=>{"matchupName"=>"Hurricanes (1) vs. Islanders (WC1)", "matchupShortName"=>"CAR v NYI", "teamAbbreviationA"=>"CAR", "teamAbbreviationB"=>"NYI", "seriesSlug"=>"hurricanes-vs-islanders-series-c"}, "currentGame"=>{"seriesSummary"=>{"gamePk"=>2022030136, "gameNumber"=>6, "gameLabel"=>"Game 6", "necessary"=>true, "gameCode"=>136, "gameTime"=>"2023-04-28T23:00:00Z", "seriesStatus"=>"Hurricanes win 4-2", "seriesStatusShort"=>"CAR wins 4-2"}}, "conference"=>{"id"=>6, "name"=>"Eastern", "link"=>"/api/v1/conferences/6"}, "round"=>{"number"=>1}, "matchupTeams"=>[{"team"=>{"id"=>12, "name"=>"Carolina Hurricanes", "link"=>"/api/v1/teams/12"}, "seed"=>{"type"=>"1", "rank"=>1, "isTop"=>true}, "seriesRecord"=>{"wins"=>4, "losses"=>2}}, {"team"=>{"id"=>2, "name"=>"New York Islanders", "link"=>"/api/v1/teams/2"}, "seed"=>{"type"=>"WC1", "rank"=>4, "isTop"=>false}, "seriesRecord"=>{"wins"=>2, "losses"=>4}}]}, {"seriesNumber"=>4, "seriesCode"=>"D", "names"=>{"matchupName"=>"Devils (2) vs. Rangers (3)", "matchupShortName"=>"NJD v NYR", "teamAbbreviationA"=>"NJD", "teamAbbreviationB"=>"NYR", "seriesSlug"=>"devils-vs-rangers-series-d"}, "currentGame"=>{"seriesSummary"=>{"gamePk"=>2022030147, "gameNumber"=>7, "gameLabel"=>"Game 7", "necessary"=>true, "gameCode"=>147, "gameTime"=>"2023-05-02T00:00:00Z", "seriesStatus"=>"Devils win 4-3", "seriesStatusShort"=>"NJD wins 4-3"}}, "conference"=>{"id"=>6, "name"=>"Eastern", "link"=>"/api/v1/conferences/6"}, "round"=>{"number"=>1}, "matchupTeams"=>[{"team"=>{"id"=>1, "name"=>"New Jersey Devils", "link"=>"/api/v1/teams/1"}, "seed"=>{"type"=>"2", "rank"=>2, "isTop"=>true}, "seriesRecord"=>{"wins"=>4, "losses"=>3}}, {"team"=>{"id"=>3, "name"=>"New York Rangers", "link"=>"/api/v1/teams/3"}, "seed"=>{"type"=>"3", "rank"=>3, "isTop"=>false}, "seriesRecord"=>{"wins"=>3, "losses"=>4}}]}, {"seriesNumber"=>5, "seriesCode"=>"E", "names"=>{"matchupName"=>"Avalanche (1) vs. Kraken (WC1)", "matchupShortName"=>"COL v SEA", "teamAbbreviationA"=>"COL", "teamAbbreviationB"=>"SEA", "seriesSlug"=>"avalanche-vs-kraken-series-e"}, "currentGame"=>{"seriesSummary"=>{"gamePk"=>2022030157, "gameNumber"=>7, "gameLabel"=>"Game 7", "necessary"=>true, "gameCode"=>157, "gameTime"=>"2023-05-01T01:30:00Z", "seriesStatus"=>"Kraken win 4-3", "seriesStatusShort"=>"SEA wins 4-3"}}, "conference"=>{"id"=>5, "name"=>"Western", "link"=>"/api/v1/conferences/5"}, "round"=>{"number"=>1}, "matchupTeams"=>[{"team"=>{"id"=>21, "name"=>"Colorado Avalanche", "link"=>"/api/v1/teams/21"}, "seed"=>{"type"=>"1", "rank"=>1, "isTop"=>true}, "seriesRecord"=>{"wins"=>3, "losses"=>4}}, {"team"=>{"id"=>55, "name"=>"Seattle Kraken", "link"=>"/api/v1/teams/55"}, "seed"=>{"type"=>"WC1", "rank"=>4, "isTop"=>false}, "seriesRecord"=>{"wins"=>4, "losses"=>3}}]}, {"seriesNumber"=>6, "seriesCode"=>"F", "names"=>{"matchupName"=>"Stars (2) vs. Wild (3)", "matchupShortName"=>"DAL v MIN", "teamAbbreviationA"=>"DAL", "teamAbbreviationB"=>"MIN", "seriesSlug"=>"stars-vs-wild-series-f"}, "currentGame"=>{"seriesSummary"=>{"gamePk"=>2022030166, "gameNumber"=>6, "gameLabel"=>"Game 6", "necessary"=>true, "gameCode"=>166, "gameTime"=>"2023-04-29T01:30:00Z", "seriesStatus"=>"Stars win 4-2", "seriesStatusShort"=>"DAL wins 4-2"}}, "conference"=>{"id"=>5, "name"=>"Western", "link"=>"/api/v1/conferences/5"}, "round"=>{"number"=>1}, "matchupTeams"=>[{"team"=>{"id"=>25, "name"=>"Dallas Stars", "link"=>"/api/v1/teams/25"}, "seed"=>{"type"=>"2", "rank"=>2, "isTop"=>true}, "seriesRecord"=>{"wins"=>4, "losses"=>2}}, {"team"=>{"id"=>30, "name"=>"Minnesota Wild", "link"=>"/api/v1/teams/30"}, "seed"=>{"type"=>"3", "rank"=>3, "isTop"=>false}, "seriesRecord"=>{"wins"=>2, "losses"=>4}}]}, {"seriesNumber"=>7, "seriesCode"=>"G", "names"=>{"matchupName"=>"Golden Knights (1) vs. Jets (WC2)", "matchupShortName"=>"VGK v WPG", "teamAbbreviationA"=>"VGK", "teamAbbreviationB"=>"WPG", "seriesSlug"=>"golden-knights-vs-jets-series-g"}, "currentGame"=>{"seriesSummary"=>{"gamePk"=>2022030175, "gameNumber"=>5, "gameLabel"=>"Game 5", "necessary"=>true, "gameCode"=>175, "gameTime"=>"2023-04-28T02:00:00Z", "seriesStatus"=>"Golden Knights win 4-1", "seriesStatusShort"=>"VGK wins 4-1"}}, "conference"=>{"id"=>5, "name"=>"Western", "link"=>"/api/v1/conferences/5"}, "round"=>{"number"=>1}, "matchupTeams"=>[{"team"=>{"id"=>54, "name"=>"Vegas Golden Knights", "link"=>"/api/v1/teams/54"}, "seed"=>{"type"=>"1", "rank"=>1, "isTop"=>true}, "seriesRecord"=>{"wins"=>4, "losses"=>1}}, {"team"=>{"id"=>52, "name"=>"Winnipeg Jets", "link"=>"/api/v1/teams/52"}, "seed"=>{"type"=>"WC2", "rank"=>4, "isTop"=>false}, "seriesRecord"=>{"wins"=>1, "losses"=>4}}]}, {"seriesNumber"=>8, "seriesCode"=>"H", "names"=>{"matchupName"=>"Oilers (2) vs. Kings (3)", "matchupShortName"=>"EDM v LAK", "teamAbbreviationA"=>"EDM", "teamAbbreviationB"=>"LAK", "seriesSlug"=>"oilers-vs-kings-series-h"}, "currentGame"=>{"seriesSummary"=>{"gamePk"=>2022030186, "gameNumber"=>6, "gameLabel"=>"Game 6", "necessary"=>true, "gameCode"=>186, "gameTime"=>"2023-04-30T02:00:00Z", "seriesStatus"=>"Oilers win 4-2", "seriesStatusShort"=>"EDM wins 4-2"}}, "conference"=>{"id"=>5, "name"=>"Western", "link"=>"/api/v1/conferences/5"}, "round"=>{"number"=>1}, "matchupTeams"=>[{"team"=>{"id"=>22, "name"=>"Edmonton Oilers", "link"=>"/api/v1/teams/22"}, "seed"=>{"type"=>"2", "rank"=>2, "isTop"=>true}, "seriesRecord"=>{"wins"=>4, "losses"=>2}}, {"team"=>{"id"=>26, "name"=>"Los Angeles Kings", "link"=>"/api/v1/teams/26"}, "seed"=>{"type"=>"3", "rank"=>3, "isTop"=>false}, "seriesRecord"=>{"wins"=>2, "losses"=>4}}]}]}, {"number"=>2, "code"=>2, "names"=>{"name"=>"Second Round", "shortName"=>"R2"}, "format"=>{"name"=>"BO7", "description"=>"Best of 7", "numberOfGames"=>7, "numberOfWins"=>4}, "series"=>[{"seriesNumber"=>1, "seriesCode"=>"I", "names"=>{"matchupName"=>"Maple Leafs (2) vs. Panthers (WC2)", "matchupShortName"=>"TOR v FLA", "teamAbbreviationA"=>"TOR", "teamAbbreviationB"=>"FLA", "seriesSlug"=>"maple-leafs-vs-panthers-series-i"}, "currentGame"=>{"seriesSummary"=>{"gamePk"=>2022030211, "gameNumber"=>1, "gameLabel"=>"Game 1", "necessary"=>true, "gameCode"=>211, "gameTime"=>"2023-05-02T23:00:00Z", "seriesStatus"=>"", "seriesStatusShort"=>""}}, "conference"=>{"id"=>6, "name"=>"Eastern", "link"=>"/api/v1/conferences/6"}, "round"=>{"number"=>2}, "matchupTeams"=>[{"team"=>{"id"=>10, "name"=>"Toronto Maple Leafs", "link"=>"/api/v1/teams/10"}, "seed"=>{"type"=>"2", "rank"=>2, "isTop"=>true}, "seriesRecord"=>{"wins"=>0, "losses"=>0}}, {"team"=>{"id"=>13, "name"=>"Florida Panthers", "link"=>"/api/v1/teams/13"}, "seed"=>{"type"=>"WC2", "rank"=>4, "isTop"=>false}, "seriesRecord"=>{"wins"=>0, "losses"=>0}}]}, {"seriesNumber"=>2, "seriesCode"=>"J", "names"=>{"matchupName"=>"Hurricanes (1) vs. Devils (2)", "matchupShortName"=>"CAR v NJD", "teamAbbreviationA"=>"CAR", "teamAbbreviationB"=>"NJD", "seriesSlug"=>"hurricanes-vs-devils-series-j"}, "currentGame"=>{"seriesSummary"=>{"gamePk"=>2022030221, "gameNumber"=>1, "gameLabel"=>"Game 1", "necessary"=>true, "gameCode"=>221, "gameTime"=>"2023-05-03T23:00:00Z", "seriesStatus"=>"", "seriesStatusShort"=>""}}, "conference"=>{"id"=>6, "name"=>"Eastern", "link"=>"/api/v1/conferences/6"}, "round"=>{"number"=>2}, "matchupTeams"=>[{"team"=>{"id"=>12, "name"=>"Carolina Hurricanes", "link"=>"/api/v1/teams/12"}, "seed"=>{"type"=>"1", "rank"=>1, "isTop"=>true}, "seriesRecord"=>{"wins"=>0, "losses"=>0}}, {"team"=>{"id"=>1, "name"=>"New Jersey Devils", "link"=>"/api/v1/teams/1"}, "seed"=>{"type"=>"2", "rank"=>2, "isTop"=>false}, "seriesRecord"=>{"wins"=>0, "losses"=>0}}]}, {"seriesNumber"=>3, "seriesCode"=>"K", "names"=>{"matchupName"=>"Stars (2) vs. Kraken (WC1)", "matchupShortName"=>"DAL v SEA", "teamAbbreviationA"=>"DAL", "teamAbbreviationB"=>"SEA", "seriesSlug"=>"stars-vs-kraken-series-k"}, "currentGame"=>{"seriesSummary"=>{"gamePk"=>2022030231, "gameNumber"=>1, "gameLabel"=>"Game 1", "necessary"=>true, "gameCode"=>231, "gameTime"=>"2023-05-03T01:30:00Z", "seriesStatus"=>"", "seriesStatusShort"=>""}}, "conference"=>{"id"=>5, "name"=>"Western", "link"=>"/api/v1/conferences/5"}, "round"=>{"number"=>2}, "matchupTeams"=>[{"team"=>{"id"=>25, "name"=>"Dallas Stars", "link"=>"/api/v1/teams/25"}, "seed"=>{"type"=>"2", "rank"=>2, "isTop"=>true}, "seriesRecord"=>{"wins"=>0, "losses"=>0}}, {"team"=>{"id"=>55, "name"=>"Seattle Kraken", "link"=>"/api/v1/teams/55"}, "seed"=>{"type"=>"WC1", "rank"=>4, "isTop"=>false}, "seriesRecord"=>{"wins"=>0, "losses"=>0}}]}, {"seriesNumber"=>4, "seriesCode"=>"L", "names"=>{"matchupName"=>"Golden Knights (1) vs. Oilers (2)", "matchupShortName"=>"VGK v EDM", "teamAbbreviationA"=>"VGK", "teamAbbreviationB"=>"EDM", "seriesSlug"=>"golden-knights-vs-oilers-series-l"}, "currentGame"=>{"seriesSummary"=>{"gamePk"=>2022030241, "gameNumber"=>1, "gameLabel"=>"Game 1", "necessary"=>true, "gameCode"=>241, "gameTime"=>"2023-05-04T01:30:00Z", "seriesStatus"=>"", "seriesStatusShort"=>""}}, "conference"=>{"id"=>5, "name"=>"Western", "link"=>"/api/v1/conferences/5"}, "round"=>{"number"=>2}, "matchupTeams"=>[{"team"=>{"id"=>54, "name"=>"Vegas Golden Knights", "link"=>"/api/v1/teams/54"}, "seed"=>{"type"=>"1", "rank"=>1, "isTop"=>true}, "seriesRecord"=>{"wins"=>0, "losses"=>0}}, {"team"=>{"id"=>22, "name"=>"Edmonton Oilers", "link"=>"/api/v1/teams/22"}, "seed"=>{"type"=>"2", "rank"=>2, "isTop"=>false}, "seriesRecord"=>{"wins"=>0, "losses"=>0}}]}]}, {"number"=>3, "code"=>3, "names"=>{"name"=>"Conference Finals", "shortName"=>"CF"}, "format"=>{"name"=>"BO7", "description"=>"Best of 7", "numberOfGames"=>7, "numberOfWins"=>4}, "series"=>[{"seriesCode"=>"M", "names"=>{"matchupName"=>"", "matchupShortName"=>"", "teamAbbreviationA"=>"", "teamAbbreviationB"=>""}, "currentGame"=>{"seriesSummary"=>{"gameLabel"=>""}}, "conference"=>{"id"=>6, "name"=>"Eastern", "link"=>"/api/v1/conferences/6"}, "round"=>{"number"=>3}}, {"seriesCode"=>"N", "names"=>{"matchupName"=>"", "matchupShortName"=>"", "teamAbbreviationA"=>"", "teamAbbreviationB"=>""}, "currentGame"=>{"seriesSummary"=>{"gameLabel"=>""}}, "conference"=>{"id"=>5, "name"=>"Western", "link"=>"/api/v1/conferences/5"}, "round"=>{"number"=>3}}]}, {"number"=>4, "code"=>4, "names"=>{"name"=>"Stanley Cup Final", "shortName"=>"SCF"}, "format"=>{"name"=>"BO7", "description"=>"Best of 7", "numberOfGames"=>7, "numberOfWins"=>4}, "series"=>[{"seriesCode"=>"O", "names"=>{"matchupName"=>"", "matchupShortName"=>"", "teamAbbreviationA"=>"", "teamAbbreviationB"=>""}, "currentGame"=>{"seriesSummary"=>{"gameLabel"=>""}}, "conference"=>{"link"=>"/api/v1/conferences/null"}, "round"=>{"number"=>4}}]}]}
    def get_playoff_standings(season)
        response = HTTParty.get('https://statsapi.web.nhl.com/api/v1/tournaments/playoffs/?expand=round.series,schedule.game.seriesSummary&season=' + season.to_s)
        puts response.parsed_response
        return response.parsed_response
    end

    # Load the playoff standings response into a hash
    def load_playoff_standings(season)
        playoff_standings_hash = get_playoff_standings(season)
        return playoff_standings_hash
    end

    # Function to determine which two combined years to query for the current seasion such as 20222023
    def current_season_years
        current_year = Time.now.year
        current_month = Time.now.month
        if current_month < 9
            current_season_years = (current_year - 1).to_s + current_year.to_s
        else
            current_season_years = current_year.to_s + (current_year + 1).to_s
        end
        return current_season_years
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
    <body class='m-2'  data-color-mode='auto' data-light-theme='light' data-dark-theme='dark_dimmed'>
    <h1 class='color-fg-success'>Hockey Team Standings</h1>
      <table class='color-shadow-large'>
        <thead class='color-bg-accent-emphasis color-fg-on-emphasis mr-1'>
                <th scope='col' class='p-2 border'>Team Name</th>
                <th scope='col' class='p-2 border'>Fan Name</th>
                <th scope='col' class='p-2 border'>Wins</th>
                <th scope='col' class='p-2 border'>Losses</th>
                <th scope='col' class='p-2 border'>OTL</th>
                <th scope='col' class='p-2 border'>Streak</th>
                <th scope='col' class='p-2 border'>Points</th>
                <th scope='col' class='p-2 border'>Point %</th>
                <th scope='col' class='p-2 border'>GPG</th>
                <th scope='col' class='p-2 border'>GA</th>
                <th scope='col' class='p-2 border'>League Rank</th>
                <th scope='col' class='p-2 border'>Conf. Name</th>
                <th scope='col' class='p-2 border'>Conf. Rank</th>
                <th scope='col' class='p-2 border'>Div. Name</th>
                <th scope='col' class='p-2 border'>Div. Rank</th>
                <th scope='col' class='p-2 border'>Wildcard Rank</th>
                <th scope='col' class='p-2 border'>Next Game Date</th>
                <th scope='col' class='p-2 border'>Next Game Opponent</th>
        </thead>
        <tbody>")
            sorted_team_stats_array.each do |team|
                # The top three teams in each division will make up the first 12 teams in the playoffs. 
                # The remaining four spots will be filled by the next two highest-placed finishers in each conference, based on regular-season record and regardless of division.
                # If team division rank is 3 or lower, color the row green with 'color-bg-success'
                if team['divisionRank'].to_i <= 3
                    f.write("<tr class='color-bg-success-emphasis color-fg-on-emphasis mr-1'>")
                # If a team is one of the next two highest-placed finishers in each conference, color the row yellow with 'color-bg-warning'
                elsif team['wildCardRank'].to_i <= 2
                    f.write("<tr class='color-bg-attention-emphasis color-fg-on-emphasis mr-1'>")
                # If a team is not eliminated from playoff contention, and is not one of the next two highest-placed finishers in each conference, color the row orange with 'color-fg-severe'
                elsif team['wildCardRank'].to_i > 2 && team['wildCardRank'].to_i <= 4
                    f.write("<tr class='color-bg-severe-emphasis color-fg-on-emphasis mr-1'>")
                # If a team is eliminated from playoff contention, color the row red with 'color-bg-danger'
                elsif team['wildCardRank'].to_i > 4
                    f.write("<tr class='color-bg-danger-emphasis color-fg-on-emphasis mr-1'>")
                else
                end
                    f.write("<td class='p-2 border'>#{team['name']}</td>
                        <td class='p-2 border'>#{team['fan']}</td>
                        <td class='p-2 border'>#{team['wins']}</td>
                        <td class='p-2 border'>#{team['losses']}</td>
                        <td class='p-2 border'>#{team['ot']}</td>
                        <td class='p-2 border'>#{team['streakCode']}</td>
                        <td class='p-2 border'>#{team['pts']}</td>
                        <td class='p-2 border'>#{team['ptPctg']}</td>
                        <td class='p-2 border'>#{team['goalsPerGame']}</td>
                        <td class='p-2 border'>#{team['goalsAgainstPerGame']}</td>
                        <td class='p-2 border'>#{team['leagueRank']}</td>
                        <td class='p-2 border'>#{team['conferenceName']}</td>
                        <td class='p-2 border'>#{team['conferenceRank']}</td>
                        <td class='p-2 border'>#{team['divisionName']}</td>
                        <td class='p-2 border'>#{team['divisionRank']}</td>
                        <td class='p-2 border'>#{team['wildCardRank']}</td>
                        <td class='p-2 border'>#{team['nextGameDate']}</td>
                        <td class='p-2 border'>#{team['nextGameOpponent']}</td>
                    </tr>")
            end
            f.write("</tbody>
        </table>         
        <span class='IssueLabel color-bg-success-emphasis color-fg-on-emphasis mr-1'>Playoff bound</span>
        <span class='IssueLabel color-bg-attention-emphasis color-fg-on-emphasis mr-1'>Playoff Contender</span>
        <span class='IssueLabel color-bg-severe-emphasis color-fg-on-emphasis mr-1'>Wildcard hopeful</span>
        <span class='IssueLabel color-bg-danger-emphasis color-fg-on-emphasis mr-1'>Not in playoff contention</span>
        <div class='border-top border-bottom border-gray-light mt-3 pt-3'>

        <h2 class='color-fg-success'>#{trophy_info['name']}</h2>
        <img src='#{trophy_info['imageUrl']}' alt='#{trophy_info['name']}' style='width: 200px;'>
        <p class='color-fg-muted'>#{trophy_info['description']}</p>
        </div>
        <a href='./playoffs.html' class='btn btn-primary'>Playoff Standings</a>

    </body>
    </html>")
        end
    end
   
    print_sorted_fan_team_stats_by_league_rank(fan_team_hash)
    output_sorted_fan_team_stats_by_league_rank(fan_team_hash)
    
    if File.file?("_site/index.html")
        puts "File created at: #{File.absolute_path("_site/index.html")}"
    end

    # Output to file a primer css styled HTML table of the playoff standings for the current season
    def output_playoff_standings(current_season)
        playoff_standings = get_playoff_standings(current_season)
      
        def generate_series_html(series)
            # Convert the gameTime from UTC to pacific time
            tz = TZInfo::Timezone.get('America/Los_Angeles')

            if series["currentGame"]["seriesSummary"]["gameTime"]
            series["currentGame"]["seriesSummary"]["gameTime"] = tz.utc_to_local(Time.parse(series["currentGame"]["seriesSummary"]["gameTime"])).strftime("%A, %b %d %Y %I:%M %p")
            end
            
            # If the matchupName is blank, set it to TBD
            if series["names"]["matchupName"] == ""
            series["names"]["matchupName"] = "TBD"
            end
          <<-HTML
            <tr>
              <td class='p-2 border'>#{series["names"]["matchupName"]}</td>
              <td class='p-2 border'>Series Status: #{series["currentGame"]["seriesSummary"]["seriesStatus"]}</td>
              <td class='p-2 border'>Game Number: #{series["currentGame"]["seriesSummary"]["gameNumber"]}</td>
              <td class='p-2 border'>Game Time: #{series["currentGame"]["seriesSummary"]["gameTime"]}</td>
            </tr>
          HTML
        end
      
        def generate_round_html(round)
          series_html = round["series"].map { |series| generate_series_html(series) }.join("\n")
          <<-HTML
            <div class="round mb-5">
              <h2 class="color-fg-success">#{round["names"]["name"]}</h2>
              <table class='color-shadow-large table table-striped'>
                <thead>
                  <tr>
                    <th scope='col' class='p-2 border'>Matchup</th>
                    <th scope='col' class='p-2 border'>Series Status</th>
                    <th scope='col' class='p-2 border'>Game Number</th>
                    <th scope='col' class='p-2 border'>Game Time</th>
                  </tr>
                </thead>
                <tbody>
                  #{series_html}
                </tbody>
              </table>
            </div>
          HTML
        end
      
        File.open("_site/playoffs.html", "w") do |f|
          f.write(<<-HTML)
      <!DOCTYPE html>
      <html lang='en'>
      <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>NHL Playoff Standings</title>
        <link rel='stylesheet' href='https://unpkg.com/@primer/css@^20.2.4/dist/primer.css'>
        <style>
          th, td {
            padding: 10px;
          }
        </style>
      </head>
      <body class='m-2' data-color-mode='auto' data-light-theme='light' data-dark-theme='dark_dimmed'>
        <div class='container-xl px-3 px-md-4 px-lg-5 mt-3'>
          <h1 class='color-fg-success'>NHL Playoff Standings</h1>
          <h2 class='color-fg-success'>#{current_season.insert(4, '-')}</h2>
          if playoff_standings["rounds"].nil?
              <h1 class='color-fg-success'>Playoff have not started!</h1>
            else
              playoff_standings["rounds"].map { |round| generate_round_html(round) }.join("\n")
          end
          <a href='./index.html' class='btn btn-primary'>Regular Season Standings</a>
        </div>
      </body>
      </html>
          HTML
        end
      end
      
    current_season = current_season_years
    output_playoff_standings(current_season)

    if File.file?("_site/playoffs.html")
        puts "File created at: #{File.absolute_path("_site/playoffs.html")}"
    end
