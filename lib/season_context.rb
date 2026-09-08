require 'date'

class SeasonContext
  attr_reader :standings_season

  def initialize(teams:, schedule_metadata: {}, today: Date.today)
    @today = today
    @regular_start = parse_date(schedule_metadata['regularSeasonStartDate'])
    @playoff_end = parse_date(schedule_metadata['playoffEndDate'])
    @standings_season = teams.first&.dig('seasonId').to_s
  end

  def offseason?
    return true if @regular_start && @today < @regular_start
    return true if @playoff_end && @today > @playoff_end
    return false if @regular_start && @playoff_end

    # Without schedule boundaries, don't promote an old season's standings.
    (7..9).cover?(@today.month) ||
      (@today.month >= 7 && @standings_season.match?(/\A\d{8}\z/) &&
       @standings_season[4, 4].to_i <= @today.year)
  end

  def standings_label
    return 'Available season' unless @standings_season.match?(/\A\d{8}\z/)

    "#{@standings_season[0, 4]}/#{@standings_season[6, 2]}"
  end

  def news_since
    Date.new(@today.month >= 6 ? @today.year : @today.year - 1, 6, 1)
  end

  private

  def parse_date(value)
    return nil if value.nil?

    Date.iso8601(value)
  rescue Date::Error, TypeError => error
    warn "Invalid NHL season boundary #{value.inspect}: #{error.message}"
    nil
  end
end
