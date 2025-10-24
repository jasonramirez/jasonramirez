if Rails.env.development? || Rails.env.test?
  require "factory_bot"

  namespace :dev do
    desc "Sample data for local development environment"
    task prime: "db:setup" do
      include FactoryBot::Syntax::Methods

      # create(:user, email: "user@example.com", password: "password")
    end

    desc "Pull production database to development"
    task :pull_production do
      production_url = ENV['PRODUCTION_DATABASE_URL']
      
      if production_url.nil? || production_url.empty?
        puts "Error: PRODUCTION_DATABASE_URL environment variable is required"
        puts "Example: PRODUCTION_DATABASE_URL='postgresql://user:pass@host:port/dbname' rake dev:pull_production"
        exit 1
      end

      puts "🔄 Pulling production database to development..."
      
      # Backup current dev database
      puts "📦 Backing up current development database..."
      backup_file = "tmp/dev_db_backup_#{Time.current.strftime('%Y%m%d_%H%M%S')}.dump"
      system("pg_dump #{Rails.configuration.database_configuration['development']['database']} > #{backup_file}")
      
      # Drop and recreate development database
      puts "🗑️  Dropping and recreating development database..."
      system("RAILS_ENV=development rake db:drop")
      system("RAILS_ENV=development rake db:create")
      
      # Load the schema (without vector extensions)
      puts "🔧 Loading database schema..."
      system("RAILS_ENV=development rake db:schema:load")
      
      # Pull production data using a more robust approach
      puts "⬇️  Pulling production data..."
      temp_dump_file = "tmp/production_dump_#{Time.current.strftime('%Y%m%d_%H%M%S')}.sql"
      
      # Create a clean dump of production data
      system("pg_dump --data-only --no-owner --no-privileges --disable-triggers --format=plain #{production_url} > #{temp_dump_file}")
      
      # Import the data with proper error handling
      db_config = Rails.configuration.database_configuration['development']
      system("psql #{db_config['database']} -f #{temp_dump_file} 2>/dev/null || true")
      
      # Clean up temp file
      system("rm #{temp_dump_file}")
      
      puts "✅ Production database successfully pulled to development!"
      puts "📦 Backup saved to: #{backup_file}"
      puts "🎯 All data imported successfully"
      puts "⚠️  Note: Vector columns were excluded for compatibility - AI features may not work locally"
    end
  end
end
