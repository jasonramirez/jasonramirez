# Configure pgvector for Rails
if Rails.env.test?
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.create_unlogged_tables = false
  
  # Silence vector type warnings in tests by raising log level
  ActiveRecord::Base.logger.level = Logger::ERROR if ActiveRecord::Base.logger
end

# Note: The neighbor gem handles vector type recognition and schema dumping
# No additional configuration needed for pgvector with Rails 8
