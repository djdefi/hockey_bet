# Team name mapping helper - provides smarter fuzzy matching between team names/nicknames and official abbreviations
# This helps with backward compatibility for the fan_team.csv file

# Method to match a team name from fan_team.csv to a team abbreviation
def map_team_name_to_abbrev(team_name, teams)
  return nil if team_name.nil? || team_name.empty?
  
  team_name_downcase = team_name.strip.downcase
  
  # Try exact abbreviation match first
  exact_match = teams.find { |team| team['teamAbbrev']['default'].downcase == team_name_downcase }
  return exact_match['teamAbbrev']['default'] if exact_match
  
  # Next, try to match against full team name
  name_match = teams.find do |team| 
    full_name = team['teamName']['default'].downcase
    full_name == team_name_downcase || 
    full_name.include?(team_name_downcase) || 
    team_name_downcase.include?(full_name)
  end
  return name_match['teamAbbrev']['default'] if name_match
  
  # Try city/region name matching
  place_match = teams.find do |team|
    place_name = team.dig('placeName', 'default')&.downcase || ''
    place_name == team_name_downcase || 
    place_name.include?(team_name_downcase) || 
    team_name_downcase.include?(place_name)
  end
  return place_match['teamAbbrev']['default'] if place_match
  
  # Levenshtein distance for nickname matching (allows for minor typos)
  best_score = Float::INFINITY
  best_match = nil
  
  teams.each do |team|
    # Try fuzzy match against team name, place name, and any other identifiers
    team_identifiers = [
      team['teamName']['default'].downcase,
      team.dig('placeName', 'default')&.downcase,
      team['teamAbbrev']['default'].downcase
    ].compact
    
    team_identifiers.each do |identifier|
      score = levenshtein_distance(team_name_downcase, identifier)
      if score < best_score && score < [team_name_downcase.length, identifier.length].min / 3
        best_score = score
        best_match = team
      end
    end
  end
  
  return best_match ? best_match['teamAbbrev']['default'] : nil
end

# Levenshtein distance calculation for fuzzy string matching
def levenshtein_distance(s, t)
  m = s.length
  n = t.length
  
  return m if n == 0
  return n if m == 0
  
  d = Array.new(m+1) { Array.new(n+1) }
  
  (0..m).each { |i| d[i][0] = i }
  (0..n).each { |j| d[0][j] = j }
  
  (1..n).each do |j|
    (1..m).each do |i|
      cost = s[i-1] == t[j-1] ? 0 : 1
      d[i][j] = [
        d[i-1][j] + 1,      # deletion
        d[i][j-1] + 1,      # insertion
        d[i-1][j-1] + cost  # substitution
      ].min
    end
  end
  
  d[m][n]
end

# Method to help map team names to abbreviations consistently
def map_team_name_to_abbrev(team_name, teams)
  return nil if team_name.nil? || team_name.empty?
  
  team_name_downcase = team_name.strip.downcase
  
  # Try direct mapping first
  if TEAM_NAME_MAPPING.key?(team_name_downcase)
    return TEAM_NAME_MAPPING[team_name_downcase]
  end
  
  # Then try fuzzy matching from our teams data
  matched_team = teams.find do |team|
    team_full_name = team['teamName']['default'].downcase
    team_abbrev = team['teamAbbrev']['default'].downcase
    
    team_full_name.include?(team_name_downcase) || 
    team_name_downcase.include?(team_full_name) || 
    team_abbrev == team_name_downcase
  end
  
  return matched_team ? matched_team['teamAbbrev']['default'] : nil
end
