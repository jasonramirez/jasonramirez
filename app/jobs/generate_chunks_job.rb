class GenerateChunksJob < ActiveJob::Base
  queue_as :default

  def perform(knowledge_item_id)
    knowledge_item = KnowledgeItem.find_by(id: knowledge_item_id)
    return unless knowledge_item

    Rails.logger.info "Generating chunks for KnowledgeItem##{knowledge_item_id}: #{knowledge_item.title}"
    
    begin
      # Remove existing chunks for this knowledge item
      KnowledgeChunk.where(knowledge_item_id: knowledge_item_id).destroy_all
      
      # Generate new chunks
      chunking_service = ContentChunkingService.new
      chunks = chunking_service.chunk_knowledge_item(knowledge_item)
      
      # Create chunks and generate embeddings
      chunks.each do |chunk_data|
        chunk = KnowledgeChunk.create!(chunk_data)
        # Embeddings will be generated automatically via after_save callback
      end
      
      Rails.logger.info "Successfully generated #{chunks.count} chunks for KnowledgeItem##{knowledge_item_id}"
    rescue => e
      Rails.logger.error "Failed to generate chunks for KnowledgeItem##{knowledge_item_id}: #{e.message}"
      raise e
    end
  end
end
