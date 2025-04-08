# NHL Standings Tracker

A live NHL standings tracker with playoff status indicators, fan ownership tracking, and upcoming game information. This project provides a clean, responsive interface for tracking teams as they advance toward the NHL Finals.

## Features

- **Live NHL Standings**: Up-to-date standings directly from the NHL API
- **Playoff Status Indicators**: Visual indicators showing which teams have clinched, are contending, or are eliminated
- **Fan Ownership Tracking**: Highlight teams owned by fans in your league
- **Upcoming Games**: Shows each team's next opponent with game time in Pacific timezone
- **Home Screen App**: Can be added to iOS/Android home screens with proper icons
- **Responsive Design**: Works well on both desktop and mobile devices
- **API Validation**: Automatically detects NHL API changes to prevent breaking

## Setup and Usage

### Prerequisites

- Ruby 3.0+ with Bundler
- Basic knowledge of CSV for team mapping

### Installation

1. Clone this repository
2. Install dependencies:
   ```
   bundle install
   ```

3. Edit `fan_team.csv` to map your fantasy league members to NHL teams:
   ```
   fan,team
   Alice,Bruins
   Bob,Maple Leafs
   ```

4. Run the update script:
   ```
   ruby update_standings.rb
   ```

5. Open `_site/index.html` in your browser to view the standings

### Deployment

The simplest way to deploy is using GitHub Pages:

1. Push your changes to GitHub
2. Enable GitHub Pages on your repository
3. Set the build directory to `_site`

## Configuration

### Fan Team Mapping

The `fan_team.csv` file maps fan names to teams. The format is simple:
```
fan,team
Alice,Bruins
Bob,Maple Leafs
```

The "team" column can use full names, city names, or common nicknames - the system will attempt to match them to the correct NHL team.

## Development

### Project Structure

- `lib/` - Core library code
  - `standings_processor.rb` - Main data processing logic
  - `api_validator.rb` - NHL API validation
  - `team_mapping.rb` - Team name/abbreviation mapping
  - `standings.html.erb` - HTML template

- `spec/` - Tests
  - `fixtures/` - Test data

### Running Tests

```
bundle exec rspec
```

Code coverage reports are automatically generated in the `coverage/` directory.

## License

[MIT License](LICENSE)
