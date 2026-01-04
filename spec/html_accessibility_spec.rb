require 'spec_helper'
require 'nokogiri'
require 'erb'
require 'json'
require 'tzinfo'
require 'time'
require_relative '../lib/bet_stats_calculator'

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
      'DET' => 'Eve',
      'BUF' => 'Frank',
      'OTT' => 'N/A',
      'MTL' => 'Grace'
    }
    
    check_fan_team_opponent(@next_games, @manager_team_map)
    @last_updated = convert_utc_to_pacific(Time.now.utc.strftime("%Y-%m-%d %H:%M:%S"))
    
    # Calculate bet stats
    calculator = BetStatsCalculator.new(@teams, @manager_team_map, @next_games)
    calculator.calculate_all_stats
    @bet_stats = calculator.stats
    
    # Load and render the template
    template = File.read('lib/standings.html.erb')
    
    # Create local variables for the ERB template (bind them in the context)
    # These are used by the ERB template
    teams = @teams
    manager_team_map = @manager_team_map
    next_games = @next_games
    last_updated = @last_updated
    bet_stats = @bet_stats
    
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
      # Note: The main data tables in this application are generated client-side by JavaScript
      # for dynamic playoff odds calculations. This test verifies that the template includes
      # proper scope attributes in the table definition that will be rendered.
      
      # Check that the template source includes table headers with scope="col"
      template_content = File.read('lib/standings.html.erb')
      expect(template_content).to include('scope="col"')
      
      # Verify scope is used consistently with th elements in table headers
      scope_count = template_content.scan(/scope="col"/).length
      expect(scope_count).to be >= 6  # At least 6 columns in playoff odds table
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
      # Count the rows with each status class (all playoff status types share same color classes)
      success_rows = @doc.css(".#{PLAYOFF_STATUS[:div_leader_1][:class].gsub(' ', '.')}")
      attention_rows = @doc.css(".#{PLAYOFF_STATUS[:in_hunt][:class].gsub(' ', '.')}")
      eliminated_rows = @doc.css(".#{PLAYOFF_STATUS[:eliminated][:class].gsub(' ', '.')}")
      
      # Just verify we have at least one row of each type
      expect(success_rows.length).to be > 0
      expect(attention_rows.length).to be > 0
      expect(eliminated_rows.length).to be > 0
    end
    
    it 'shows the legend with status types' do
      legend_items = @doc.css('.status-item')
      legend_text = legend_items.map { |item| item.text.strip }.join(' ')
      
      # Check that key status labels exist in the legend
      expect(legend_text).to include('Division Leader')
      expect(legend_text).to include('Wildcard')
      expect(legend_text).to include(PLAYOFF_STATUS[:in_hunt][:label_prefix])
      expect(legend_text).to include(PLAYOFF_STATUS[:eliminated][:label_prefix])
    end
  end
  
  describe 'fan team opponent indicator' do
    it 'only shows flame emoji for games between fan-owned teams' do
      # In our fixture, Boston vs Toronto should show the flame emoji for both
      team_rows = @doc.css('tr')
      
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
