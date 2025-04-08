# Run yarn install if a package.json exists when the container is created
# Run bundle install to install required gems
# Run the RSpec tests to validate the setup

set -e  # Exit immediately if a command exits with a non-zero status

echo "🧶 Installing dependencies..."
if [ -f "package.json" ]; then
  yarn install || { echo "⚠️ Yarn install failed"; exit 1; }
fi

echo "💎 Installing Ruby gems..."
bundle install || { echo "⚠️ Bundle install failed"; exit 1; }

echo "🔍 Validating Ruby version..."
ruby -v || { echo "⚠️ Ruby version check failed"; exit 1; }

echo "🧪 Running tests to validate setup..."
bundle exec rspec || { echo "⚠️ Tests failed"; exit 1; }

echo "🚀 Your development environment is ready!"
