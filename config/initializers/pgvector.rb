# Configure pgvector for Rails
if defined?(Pgvector)
  # Register vector type with Active Record
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.create_unlogged_tables = false if Rails.env.test?
  
  # Silence vector type warnings in tests
  ActiveRecord::Base.logger.level = Logger::WARN if Rails.env.test?
end
