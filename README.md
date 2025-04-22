# NHL Hockey Bet Tracker

A live NHL standings and playoff tracker with playoff status indicators, fan ownership tracking, and upcoming game information. This project provides a clean, responsive interface for tracking teams as they advance toward the Stanley Cup Finals.

## Features

- **Live NHL Standings**: Up-to-date standings directly from the NHL API
- **Playoff Brackets**: Complete playoff bracket display with series scores and game schedules
- **Playoff Status Indicators**: Visual indicators showing which teams have clinched, are contending, or are eliminated
- **Fan Ownership Tracking**: Highlight teams owned by fans in your league with flame emoji (🔥) indicators
- **Upcoming Games**: Shows each team's next opponent with game time in Pacific timezone
- **Home Screen App**: Can be added to iOS/Android home screens with proper icons
- **Responsive Design**: Works well on both desktop and mobile devices
- **API Validation**: Automatically validates different NHL API formats to ensure reliable data display
- **GitHub Codespaces Compatible**: Runs seamlessly in GitHub Codespaces with system Ruby 3.4.2

## Setup and Usage

### Prerequisites

- Ruby 3.4+ with Bundler (automatically provided in GitHub Codespaces)
- Basic knowledge of CSV for team mapping

### Installation

1. Clone this repository
2. If using GitHub Codespaces, everything is pre-configured for you
3. If running locally, install dependencies:
   ```bash
   bin/setup
   ```

### Running the Application

The project includes standardized scripts in the `bin/` directory:

1. **Setup the environment**:
   ```bash
   bin/setup
   ```

2. **Update NHL data**:
   ```bash
   bin/update
   ```

3. **Run tests**:
   ```bash
   bin/test
   ```

4. **Start the local server**:
   ```bash
   bin/server
   ```
   Then open http://localhost:8000 in your browser

### Customization

1. Edit `fan_team.csv` to map your fantasy league members to NHL teams:
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
