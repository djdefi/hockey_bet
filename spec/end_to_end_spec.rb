require 'spec_helper'
require 'nokogiri'
require 'fileutils'
require 'tmpdir'

RSpec.describe 'End-to-End Generation and Rendering' do
  let(:output_dir) { Dir.mktmpdir }
  let(:output_path) { File.join(output_dir, 'index.html') }
  let(:csv_path) { 'spec/fixtures/fan_team.csv' }
  
  after do
    FileUtils.rm_rf(output_dir) if Dir.exist?(output_dir)
  end
  
  describe 'Complete generation pipeline' do
    it 'successfully generates a complete HTML page from start to finish' do
      processor = StandingsProcessor.new('spec/fixtures')
      
      # Mock the API calls to use fixtures
      allow(processor).to receive(:fetch_team_info).and_return(
        JSON.parse(File.read('spec/fixtures/teams.json'))['standings']
      )
      allow(processor).to receive(:fetch_schedule_info).and_return(
        JSON.parse(File.read('spec/fixtures/schedule.json'))['gameWeek']
      )
      allow(processor.playoff_processor).to receive(:fetch_playoff_data).and_return(true)
      
      # Run the complete pipeline
      processor.fetch_data
      processor.process_data(csv_path)
      processor.render_output(output_path)
      
      # Verify output was created
      expect(File.exist?(output_path)).to be true
      
      # Parse and validate HTML structure
      html = File.read(output_path)
      doc = Nokogiri::HTML(html)
      
      # Validate basic HTML structure
      expect(doc.at('html')['lang']).to eq('en')
      expect(doc.at('title').text).to eq('NHL Standings')
      expect(doc.css('h1').any?).to be true
      
      # Validate that team cards are present for fan teams
      team_cards = doc.css('.team-card')
      expect(team_cards.length).to be > 0
      
      # Verify status classes are applied
      success_cards = doc.css('.team-card.color-bg-success-emphasis')
      expect(success_cards.length).to be > 0
      
      # Verify all required assets were copied
      output_dir_path = File.dirname(output_path)
      expect(File.exist?(File.join(output_dir_path, 'styles.css'))).to be true
      expect(Dir.exist?(File.join(output_dir_path, 'vendor'))).to be true
    end
    
    it 'generates HTML with accurate team data from fixtures' do
      processor = StandingsProcessor.new('spec/fixtures')
      
      teams_data = JSON.parse(File.read('spec/fixtures/teams.json'))['standings']
      schedule_data = JSON.parse(File.read('spec/fixtures/schedule.json'))['gameWeek']
      
      allow(processor).to receive(:fetch_team_info).and_return(teams_data)
      allow(processor).to receive(:fetch_schedule_info).and_return(schedule_data)
      allow(processor.playoff_processor).to receive(:fetch_playoff_data).and_return(true)
      
      processor.fetch_data
      processor.process_data(csv_path)
      processor.render_output(output_path)
      
      html = File.read(output_path)
      doc = Nokogiri::HTML(html)
      
      # Verify Boston Bruins data is accurately rendered
      boston_card = doc.css('.team-card[data-team-id="BOS"]').first
      expect(boston_card).not_to be_nil
      
      # Check team name
      team_name = boston_card.css('.team-name').first.text
      expect(team_name).to eq('Boston Bruins')
      
      # Check points (from fixture: 106 points)
      points_value = boston_card.css('.team-points-value').first.text
      expect(points_value).to eq('106')
      
      # Verify playoff status is displayed
      status_badge = boston_card.css('.status-badge').first
      expect(status_badge).not_to be_nil
      expect(status_badge.text).to include('Division Leader')
    end
    
    it 'correctly processes and displays next game information' do
      processor = StandingsProcessor.new('spec/fixtures')
      
      teams_data = JSON.parse(File.read('spec/fixtures/teams.json'))['standings']
      schedule_data = JSON.parse(File.read('spec/fixtures/schedule.json'))['gameWeek']
      
      allow(processor).to receive(:fetch_team_info).and_return(teams_data)
      allow(processor).to receive(:fetch_schedule_info).and_return(schedule_data)
      allow(processor.playoff_processor).to receive(:fetch_playoff_data).and_return(true)
      
      processor.fetch_data
      processor.process_data(csv_path)
      
      # Verify next games were found
      expect(processor.next_games).not_to be_empty
      
      # Check that fan team opponent flags are set correctly
      processor.next_games.each do |team_abbrev, game|
        expect(game).to have_key('isFanTeamOpponent')
      end
    end
    
    it 'handles teams without next games gracefully' do
      processor = StandingsProcessor.new('spec/fixtures')
      
      teams_data = JSON.parse(File.read('spec/fixtures/teams.json'))['standings']
      schedule_data = []  # Empty schedule - no games
      
      allow(processor).to receive(:fetch_team_info).and_return(teams_data)
      allow(processor).to receive(:fetch_schedule_info).and_return(schedule_data)
      allow(processor.playoff_processor).to receive(:fetch_playoff_data).and_return(true)
      
      processor.fetch_data
      processor.process_data(csv_path)
      processor.render_output(output_path)
      
      # Should complete without errors
      expect(File.exist?(output_path)).to be true
      
      # Verify placeholders were created
      processor.next_games.each do |team_abbrev, game|
        # All games should have None placeholders
        expect(game['startTimeUTC']).to eq('None')
        expect(game['awayTeam']['abbrev']).to eq('None')
        expect(game['homeTeam']['abbrev']).to eq('None')
      end
    end
    
    it 'correctly calculates and displays bet statistics' do
      processor = StandingsProcessor.new('spec/fixtures')
      
      teams_data = JSON.parse(File.read('spec/fixtures/teams.json'))['standings']
      schedule_data = JSON.parse(File.read('spec/fixtures/schedule.json'))['gameWeek']
      
      allow(processor).to receive(:fetch_team_info).and_return(teams_data)
      allow(processor).to receive(:fetch_schedule_info).and_return(schedule_data)
      allow(processor.playoff_processor).to receive(:fetch_playoff_data).and_return(true)
      
      processor.fetch_data
      processor.process_data(csv_path)
      
      # Verify bet stats were calculated
      expect(processor.bet_stats).not_to be_nil
      expect(processor.bet_stats).to be_a(Hash)
      
      # Check for expected stat categories
      expect(processor.bet_stats).to have_key(:top_winners)
      expect(processor.bet_stats).to have_key(:top_losers)
      expect(processor.bet_stats).to have_key(:best_cup_odds)
      
      # Verify stats have content
      expect(processor.bet_stats[:top_winners]).to be_an(Array)
    end
    
    it 'maintains data consistency across multiple runs' do
      processor = StandingsProcessor.new('spec/fixtures')
      
      teams_data = JSON.parse(File.read('spec/fixtures/teams.json'))['standings']
      schedule_data = JSON.parse(File.read('spec/fixtures/schedule.json'))['gameWeek']
      
      allow(processor).to receive(:fetch_team_info).and_return(teams_data)
      allow(processor).to receive(:fetch_schedule_info).and_return(schedule_data)
      allow(processor.playoff_processor).to receive(:fetch_playoff_data).and_return(true)
      
      # First run
      processor.fetch_data
      processor.process_data(csv_path)
      processor.render_output(output_path)
      
      first_html = File.read(output_path)
      
      # Second run with same data
      output_path2 = File.join(output_dir, 'index2.html')
      processor2 = StandingsProcessor.new('spec/fixtures')
      
      allow(processor2).to receive(:fetch_team_info).and_return(teams_data)
      allow(processor2).to receive(:fetch_schedule_info).and_return(schedule_data)
      allow(processor2.playoff_processor).to receive(:fetch_playoff_data).and_return(true)
      
      processor2.fetch_data
      processor2.process_data(csv_path)
      processor2.render_output(output_path2)
      
      second_html = File.read(output_path2)
      
      # Parse both to compare key data (excluding timestamps)
      doc1 = Nokogiri::HTML(first_html)
      doc2 = Nokogiri::HTML(second_html)
      
      # Compare team card counts
      expect(doc1.css('.team-card').length).to eq(doc2.css('.team-card').length)
      
      # Compare team data (points should match)
      doc1.css('.team-card').each_with_index do |card1, idx|
        card2 = doc2.css('.team-card')[idx]
        points1 = card1.css('.team-points-value').first.text
        points2 = card2.css('.team-points-value').first.text
        expect(points1).to eq(points2)
      end
    end
  end
  
  describe 'Rendered output validation' do
    before do
      processor = StandingsProcessor.new('spec/fixtures')
      
      teams_data = JSON.parse(File.read('spec/fixtures/teams.json'))['standings']
      schedule_data = JSON.parse(File.read('spec/fixtures/schedule.json'))['gameWeek']
      
      allow(processor).to receive(:fetch_team_info).and_return(teams_data)
      allow(processor).to receive(:fetch_schedule_info).and_return(schedule_data)
      allow(processor.playoff_processor).to receive(:fetch_playoff_data).and_return(true)
      
      processor.fetch_data
      processor.process_data(csv_path)
      processor.render_output(output_path)
      
      @html = File.read(output_path)
      @doc = Nokogiri::HTML(@html)
    end
    
    it 'includes all critical meta tags for PWA' do
      expect(@doc.at('link[rel="manifest"]')).not_to be_nil
      expect(@doc.at('meta[name="apple-mobile-web-app-capable"]')).not_to be_nil
      expect(@doc.at('meta[name="theme-color"]')).not_to be_nil
      expect(@doc.at('meta[name="viewport"]')).not_to be_nil
    end
    
    it 'includes all required JavaScript files' do
      scripts = @doc.css('script[src]').map { |s| s['src'] }
      
      expect(scripts).to include('vendor/chart.umd.js')
      expect(scripts).to include('performance-utils.js')
      expect(scripts).to include('accessibility.js')
      expect(scripts).to include('social-features.js')
      expect(scripts).to include('mobile-gestures.js')
    end
    
    it 'includes navigation tabs for desktop' do
      tabs = @doc.css('.desktop-tab')
      expect(tabs.length).to be >= 4
      
      tab_labels = tabs.map { |t| t.text }
      expect(tab_labels).to include('League')
      expect(tab_labels).to include('Matchups')
      expect(tab_labels).to include('Standings')
    end
    
    it 'renders fan team cards with all required information' do
      team_cards = @doc.css('.team-card')
      
      team_cards.each do |card|
        # Should have team rank
        expect(card.css('.team-rank').length).to be > 0
        
        # Should have team name
        expect(card.css('.team-name').length).to be > 0
        
        # Should have fan name
        expect(card.css('.team-fan').length).to be > 0
        
        # Should have points
        expect(card.css('.team-points-value').length).to be > 0
        
        # Should have status badge
        expect(card.css('.status-badge').length).to be > 0
      end
    end
    
    it 'displays accurate playoff status for each team' do
      # Boston should be Division Leader 1
      boston_card = @doc.css('.team-card[data-team-id="BOS"]').first
      expect(boston_card['class']).to include('color-bg-success-emphasis')
      status_text = boston_card.css('.status-badge').first.text
      expect(status_text).to include('Division Leader')
    end
    
    it 'shows last updated timestamp' do
      last_updated = @doc.css('.text-secondary').find { |el| el.text.include?('Last updated') }
      expect(last_updated).not_to be_nil
      expect(last_updated.text).to match(/\d{4}-\d{2}-\d{2}/)
    end
    
    it 'includes status legend for users' do
      legend_items = @doc.css('.status-item')
      expect(legend_items.length).to be >= 4
      
      legend_text = legend_items.map { |item| item.text }.join(' ')
      expect(legend_text).to include('Division Leader')
      expect(legend_text).to include('Wildcard')
    end
  end
  
  describe 'Error handling and edge cases' do
    it 'handles missing CSV file gracefully' do
      processor = StandingsProcessor.new('spec/fixtures')
      
      teams_data = JSON.parse(File.read('spec/fixtures/teams.json'))['standings']
      schedule_data = JSON.parse(File.read('spec/fixtures/schedule.json'))['gameWeek']
      
      allow(processor).to receive(:fetch_team_info).and_return(teams_data)
      allow(processor).to receive(:fetch_schedule_info).and_return(schedule_data)
      allow(processor.playoff_processor).to receive(:fetch_playoff_data).and_return(true)
      
      processor.fetch_data
      
      # Use non-existent CSV file
      expect {
        processor.process_data('nonexistent.csv')
      }.not_to raise_error
      
      # All teams should be N/A
      processor.manager_team_map.each do |team_abbrev, fan|
        expect(fan).to eq('N/A')
      end
    end
    
    it 'handles malformed team data gracefully' do
      processor = StandingsProcessor.new('spec/fixtures')
      
      # Create team data with missing fields
      teams_data = [
        {
          'teamName' => { 'default' => 'Test Team' },
          'teamAbbrev' => { 'default' => 'TST' },
          'points' => nil,  # Missing points
          'divisionSequence' => 1,
          'wildcardSequence' => 0
        }
      ]
      
      allow(processor).to receive(:fetch_team_info).and_return(teams_data)
      allow(processor).to receive(:fetch_schedule_info).and_return([])
      allow(processor.playoff_processor).to receive(:fetch_playoff_data).and_return(true)
      
      expect {
        processor.fetch_data
        processor.process_data(csv_path)
        processor.render_output(output_path)
      }.not_to raise_error
      
      # Should still generate HTML
      expect(File.exist?(output_path)).to be true
    end
  end
end
