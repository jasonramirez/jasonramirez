class Admins::AdditionalKnowledgesController < ApplicationController
  layout 'admin'
  before_action :authenticate_admin!
  before_action :set_additional_knowledge, only: [:edit, :update, :destroy]

  def index
    @additional_knowledges = AdditionalKnowledge.by_created
    
    # Knowledge base overview - three main categories
    @posts_count = KnowledgeItem.where(category: 'Blog Post').count
    @case_studies_count = KnowledgeItem.where(category: 'Case Study').count
    @additional_knowledge_count = AdditionalKnowledge.count
    
    @total_knowledge_items = @posts_count + @case_studies_count + @additional_knowledge_count
    @total_chunks = KnowledgeChunk.count
    
    # Check for pending items that need to be added to knowledge base
    @published_posts = Post.where(published: true)
    knowledge_item_sources = KnowledgeItem.where(category: 'Blog Post').pluck(:source)
    # Convert "post_123" format to actual post IDs
    existing_post_ids = knowledge_item_sources.map { |source| source.gsub('post_', '').to_i }
    @pending_posts = @published_posts.where.not(id: existing_post_ids)
    @pending_posts_count = @pending_posts.count
    
    # Case studies are hardcoded files - show what's already in knowledge base
    @case_study_posts = []
    @knowledge_base_case_studies = KnowledgeItem.where(category: 'Case Study').order(:title)
    @knowledge_base_case_studies_count = @knowledge_base_case_studies.count
    
    # Define expected case studies (hardcoded files that should be in knowledge base)
    expected_case_studies = [
      "Dropbox Keeping Flow",
      "Mayo Clinic Gamifying Medical Education", 
      "We Ate The Web Saving Money"
    ]
    
    # Find case studies that are missing from knowledge base
    existing_case_study_titles = @knowledge_base_case_studies.pluck(:title)
    @pending_case_studies = expected_case_studies - existing_case_study_titles
    @pending_case_studies_count = @pending_case_studies.count
    
    @total_pending = @pending_posts_count + @pending_case_studies_count
  end


  def new
    @additional_knowledge = AdditionalKnowledge.new
  end

  def create
    @additional_knowledge = AdditionalKnowledge.new(additional_knowledge_params)

    respond_to do |format|
      if @additional_knowledge.save
        format.html { redirect_to edit_admins_additional_knowledge_path(@additional_knowledge), 
                      notice: 'Additional knowledge was successfully created.' }
        format.turbo_stream { redirect_to admins_additional_knowledges_path, 
                              notice: 'Additional knowledge was successfully created.' }
      else
        format.html { render :new }
        format.turbo_stream { render :new }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @additional_knowledge.update(additional_knowledge_params)
        format.html { redirect_to admins_additional_knowledge_path(@additional_knowledge), 
                      notice: 'Additional knowledge was successfully updated.' }
        format.turbo_stream { redirect_to admins_additional_knowledges_path, 
                              notice: 'Additional knowledge was successfully updated.' }
      else
        format.html { render :edit }
        format.turbo_stream { render :edit }
      end
    end
  end

  def destroy
    @additional_knowledge.destroy
    redirect_to admins_additional_knowledges_path, 
                notice: 'Additional knowledge was successfully deleted.'
  end

  def update_knowledge_base
    begin
      service = KnowledgeImportService.new
      result = service.import_all
      
      if result
        redirect_to admins_additional_knowledges_path, 
                    notice: 'Knowledge base updated successfully!'
      else
        redirect_to admins_additional_knowledges_path, 
                    alert: 'Knowledge base update failed. Check logs for details.'
      end
    rescue => e
      Rails.logger.error "Knowledge base update error: #{e.message}"
      redirect_to admins_additional_knowledges_path, 
                  alert: "Knowledge base update failed: #{e.message}"
    end
  end

  def generate_embeddings
    begin
      # Queue embedding generation for all knowledge items that don't have them
      items_without_embeddings = KnowledgeItem.where(content_embedding: nil)
      items_queued = 0
      
      items_without_embeddings.find_each(batch_size: 10) do |item|
        GenerateEmbeddingsJob.perform_later('KnowledgeItem', item.id)
        items_queued += 1
      end
      
      # Also queue embeddings for additional knowledge items
      additional_knowledge_without_embeddings = AdditionalKnowledge.where(content_embedding: nil)
      additional_knowledge_without_embeddings.find_each(batch_size: 10) do |item|
        GenerateEmbeddingsJob.perform_later('AdditionalKnowledge', item.id)
        items_queued += 1
      end
      
      redirect_to admins_additional_knowledges_path, 
                  notice: "Embedding generation queued for #{items_queued} items! This will run in the background."
    rescue => e
      Rails.logger.error "Embedding generation error: #{e.message}"
      redirect_to admins_additional_knowledges_path, 
                  alert: "Embedding generation failed: #{e.message}"
    end
  end

  def generate_chunks
    begin
      # Generate chunks for all knowledge items
      total_items = KnowledgeItem.count
      items_processed = 0
      
      KnowledgeItem.find_each(batch_size: 3) do |item|
        GenerateChunksJob.perform_later(item.id)
        items_processed += 1
        sleep(0.2) # Small delay to avoid overwhelming the job queue
      end
      
      redirect_to admins_additional_knowledges_path, 
                  notice: "Chunk generation queued for #{items_processed} knowledge items! This will run in the background."
    rescue => e
      Rails.logger.error "Chunk generation error: #{e.message}"
      redirect_to admins_additional_knowledges_path, 
                  alert: "Chunk generation failed: #{e.message}"
    end
  end

  private

  def set_additional_knowledge
    @additional_knowledge = AdditionalKnowledge.find(params[:id])
  end

  def additional_knowledge_params
    params.require(:additional_knowledge).permit(:title, :content)
  end
end
