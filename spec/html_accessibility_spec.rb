require 'spec_helper'
require 'nokogiri'
require 'erb'
require 'json'
require 'tzinfo'
require 'time'

RSpec.describe 'HTML Rendering and Accessibility' do
  before do
    # Load test fixtures
    teams_json = File.read('spec/fixtures/teams.json')
    schedule_json = File.read('spec/fixtures/schedule.json')
    
    @teams = JSON.parse(teams_json)['standings']
    @schedule = JSON.parse(schedule_json)['gameWeek']
    @next_games = find_next_games(@teams, @schedule)
    @manager_team_map = {
      'BOS' => 'Alice',
      'TOR' => 'Bob',
      'FLA' => 'Charlie',
      'TBL' => 'Dave',
      'DET' => 'N/A',
      'BUF' => 'N/A',
      'OTT' => 'N/A',
      'MTL' => 'N/A'
    }
    
    check_fan_team_opponent(@next_games, @manager_team_map)
    @last_updated = convert_utc_to_pacific(Time.now.utc.strftime("%Y-%m-%d %H:%M:%S"))
    
    # Load and render the template
    template = File.read('lib/standings.html.erb')
    
    # Create local variables for the ERB template
    teams = @teams
    manager_team_map = @manager_team_map
    next_games = @next_games
    last_updated = @last_updated
    
    html_content = ERB.new(template).result(binding)
    @doc = Nokogiri::HTML(html_content)
  end

  describe 'HTML structure and accessibility' do
    it 'has an HTML lang attribute' do
      expect(@doc.at('html')['lang']).to eq('en')
    end
    
    it 'has a proper title' do
      expect(@doc.at('title').text).to eq('NHL Standings')
    end
    
    it 'has headings in the proper order' do
      headings = @doc.search('h1, h2, h3, h4, h5, h6').map(&:name)
      expect(headings.first).to eq('h1')
    end
    
    it 'has status icons with aria-label attributes' do
      status_icons = @doc.css('span[role="img"]')
      expect(status_icons.length).to be > 0
      
      status_icons.each do |icon|
        expect(icon['aria-label']).not_to be_nil
        expect(icon['aria-label']).not_to be_empty
      end
    end
    
    it 'has table headers with scope attributes' do
      th_elements = @doc.css('th')
      expect(th_elements.length).to be > 0
      
      th_elements.each do |th|
        expect(th['scope']).to eq('col')
      end
    end
    
    it 'has proper button attributes for accessibility' do
      buttons = @doc.css('button')
      expect(buttons.length).to be > 0
      
      buttons.each do |button|
        expect(button['aria-label']).not_to be_nil
      end
    end
  end
  
  describe 'playoff status displays' do
    it 'correctly applies status classes to rows' do
      # Count the rows with each status class
      clinched_rows = @doc.css(".#{PLAYOFF_STATUS[:clinched][:class].gsub(' ', '.')}")
      contending_rows = @doc.css(".#{PLAYOFF_STATUS[:contending][:class].gsub(' ', '.')}")
      eliminated_rows = @doc.css(".#{PLAYOFF_STATUS[:eliminated][:class].gsub(' ', '.')}")
      
      # Just verify we have at least one row of each type
      expect(clinched_rows.length).to be > 0
      expect(contending_rows.length).to be > 0
      expect(eliminated_rows.length).to be > 0
    end
    
    it 'shows the legend with all status types' do
      legend_items = @doc.css('.status-item')
      legend_text = legend_items.map { |item| item.text.strip }.join(' ')
      
      # Check that each status label exists somewhere in the combined legend text
      expect(legend_text).to include(PLAYOFF_STATUS[:clinched][:label])
      expect(legend_text).to include(PLAYOFF_STATUS[:contending][:label])
      expect(legend_text).to include(PLAYOFF_STATUS[:eliminated][:label])
    end
  end
  
  describe 'fan team opponent indicator' do
    it 'only shows flame emoji for games between fan-owned teams' do
      # In our fixture, Boston vs Toronto should show the flame emoji for both
      team_rows = @doc.css('tr')
      
      fan_team_opponents = team_rows.select do |row|
        cells = row.css('td')
        team_name = cells[0]&.text&.strip
        flame_emoji_present = cells[-1]&.text&.include?('🔥')
        
        # If this team has a flame emoji
        if flame_emoji_present
          # Verify both teams have fans
          opponent_name = cells[-1]&.text&.gsub('🔥', '')&.strip
          team_has_fan = @manager_team_map[team_abbrev_for(team_name)] != 'N/A'
          opponent_has_fan = find_opponent_fan(opponent_name)
          
          team_has_fan && opponent_has_fan
        else
          false
        end
      end
      
      # Check the logic for a few expected cases
      team_rows.each do |row|
        cells = row.css('td')
        team_name = cells[0]&.text&.strip
        next unless team_name
        
        opponent_cell = cells[-1]
        next unless opponent_cell
        
        opponent_name = opponent_cell.text.gsub('🔥', '').strip
        flame_emoji_present = opponent_cell.text.include?('🔥')
        
        if team_name == 'Boston Bruins' && opponent_name.include?('Toronto')
          # Boston vs Toronto - both have fans, should have flame
          expect(flame_emoji_present).to be(true)
        elsif team_name == 'Detroit Red Wings' && opponent_name.include?('Buffalo')
          # Detroit vs Buffalo - neither have fans, should not have flame
          expect(flame_emoji_present).to be(false)
        end
      end
    end
    
    # Helper methods for the tests
    def team_abbrev_for(team_name)
      @teams.find { |t| t['teamName']['default'] == team_name }&.dig('teamAbbrev', 'default')
    end
    
    def find_opponent_fan(opponent_name)
      # Simplification for test - this assumes opponent_name contains the place name
      team = @teams.find { |t| t['teamName']['default'].include?(opponent_name) || opponent_name.include?(t['teamName']['default']) }
      abbrev = team&.dig('teamAbbrev', 'default')
      abbrev && @manager_team_map[abbrev] != 'N/A'
    end
  end
end
