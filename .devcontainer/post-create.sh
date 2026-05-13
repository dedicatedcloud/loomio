#!/bin/bash
set -e

echo "🔧 Starting Loomio development environment setup..."

# Update package lists
echo "📦 Updating system packages..."
sudo apt-get update

# Install system dependencies from DEVSETUP.md requirements
echo "⬇️ Installing system dependencies..."
sudo apt-get install -y \
  postgresql-contrib \
  libssl-dev \
  libreadline-dev \
  zlib1g-dev \
  libpq-dev \
  libffi-dev \
  libmagickwand-dev \
  imagemagick \
  python3 \
  libyaml-dev \
  git \
  libvips \
  ffmpeg \
  poppler-utils

# Setup rbenv for Ruby version management
echo "🔨 Setting up rbenv..."
if [ ! -d "$HOME/.rbenv" ]; then
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
fi

if [ ! -d "$HOME/.rbenv/plugins/ruby-build" ]; then
  mkdir -p ~/.rbenv/plugins
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi

export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"

# Install Ruby version from .ruby-version file
echo "💎 Installing Ruby..."
RUBY_VERSION=$(cat .ruby-version)
rbenv install -s "$RUBY_VERSION"
rbenv local "$RUBY_VERSION"

# Install Bundler
echo "📚 Installing Bundler..."
gem install bundler

# Install Ruby dependencies
echo "💿 Installing Ruby gems..."
bundle install

# Install Node dependencies
echo "🟢 Installing Node dependencies..."
cd vue
npm install
cd ..

# Setup database configuration
echo "🗄️ Setting up database..."
if [ ! -f config/database.yml ]; then
  cp config/database.example.yml config/database.yml
fi

# Create PostgreSQL user and database (if needed)
echo "🐘 Setting up PostgreSQL..."
if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw loomio_development; then
  sudo -u postgres createuser --superuser vscode 2>/dev/null || true
  sudo -u postgres createdb -O vscode loomio_development
  sudo -u postgres createdb -O vscode loomio_test
fi

# Update database.yml to use local postgres
echo "⚙️ Configuring database connection..."
sed -i 's/username:.*/username: vscode/' config/database.yml
sed -i 's/password:.*/password:/' config/database.yml

# Setup database schema
echo "🏗️ Setting up database schema..."
rake db:setup || rake db:create && rake db:schema:load

# Precompile assets (optional, for faster startup)
echo "🎨 Preparing assets..."
bundle exec vite build

echo ""
echo "✅ Loomio development environment is ready!"
echo ""
echo "Next steps:"
echo "  1. Start the development server with: bin/dev"
echo "  2. Open http://localhost:8080 in your browser"
echo "  3. Check out http://localhost:8080/dev/ for dev routes"
echo ""
echo "Useful commands:"
echo "  rails s          - Start Rails server"
echo "  rails c          - Rails console"
echo "  rails test       - Run tests"
echo "  bin/e2e          - Run E2E tests"
echo ""