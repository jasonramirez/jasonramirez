class GenerateEmbeddingsJob < ActiveJob::Base
  queue_as :default

  def perform(model_class, record_id)
    record = model_class.constantize.find_by(id: record_id)
    return unless record

    Rails.logger.info "Generating embeddings for #{model_class}##{record_id}"
    
    begin
      record.generate_embeddings
      Rails.logger.info "Successfully generated embeddings for #{model_class}##{record_id}"
    rescue => e
      Rails.logger.error "Failed to generate embeddings for #{model_class}##{record_id}: #{e.message}"
      raise e # Re-raise to trigger retry logic if configured
    end
  end
end
