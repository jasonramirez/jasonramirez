# Configure pgvector for Rails
if Rails.env.test?
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.create_unlogged_tables = false
  
  # Silence vector type warnings in tests by raising log level
  ActiveRecord::Base.logger.level = Logger::ERROR if ActiveRecord::Base.logger
end
