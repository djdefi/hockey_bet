module CupPath
  # Use NHL sequences, including its tiebreakers, rather than re-ranking by points.
  def self.conferences(teams)
    teams.group_by { |team| team['conferenceName'] }.filter_map do |name, members|
      next unless name

      divisions = members.group_by { |team| team['divisionName'] }.values
      leaders = divisions.filter_map { |division| division.find { |team| team['divisionSequence'] == 1 } }
                         .sort_by { |team| team['conferenceSequence'].to_i }
      wildcards = members.select { |team| [1, 2].include?(team['wildcardSequence']) }
                         .sort_by { |team| team['wildcardSequence'] }
      branches = leaders.each_with_index.map do |leader, index|
        division = members.select { |team| team['divisionName'] == leader['divisionName'] }
        {
          name: leader['divisionName'],
          teams: [leader, wildcards[1 - index],
                  division.find { |team| team['divisionSequence'] == 2 },
                  division.find { |team| team['divisionSequence'] == 3 }]
        }
      end
      ready = divisions.size == 2 && leaders.size == 2 && wildcards.size == 2 &&
              branches.all? { |branch| branch[:teams].none?(&:nil?) } &&
              members.any? { |team| team['gamesPlayed'].to_i.positive? }
      { name: name, teams: members, branches: branches, ready: ready }
    end.sort_by { |conference| conference[:name] }
  end
end
