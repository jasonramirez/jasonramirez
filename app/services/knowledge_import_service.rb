class KnowledgeImportService
  def initialize(directory_path = nil)
    @directory_path = directory_path || Rails.root.join('app', 'assets', 'knowledge')
  end

  def import_all
    log "🌱 Starting comprehensive knowledge base import..."
    
    # Import published posts
    imported_post_ids = import_published_posts
    
    # Import case studies
    imported_case_study_ids = import_case_studies
    
    # Queue chunk generation for all imported items
    all_imported_ids = imported_post_ids + imported_case_study_ids
    queue_chunk_generation(all_imported_ids)
    
    log "✅ Knowledge base import complete!"
    log "📊 Total knowledge items: #{KnowledgeItem.count}"
    log "🧩 Queued chunk generation for #{all_imported_ids.count} items"
  end

  def import_published_posts
    log "📝 Importing published posts..."
    imported_ids = []
    
    Post.where(published: true).each do |post|
      knowledge_item = KnowledgeItem.find_or_initialize_by(
        title: post.title,
        source: "post_#{post.id}"
      )
      
      # Use post_text for content if available, fallback to post_markdown
      content_text = post.post_text.present? ? post.post_text : post.post_markdown
      
      knowledge_item.assign_attributes(
        content: content_text,
        category: 'Blog Post',
        tags: post.hashtags.map(&:label).join(', '),
        confidence_score: 0.9,
        last_updated: post.updated_at
      )
      
      knowledge_item.save!
      imported_ids << knowledge_item.id
      log "  ✅ Imported post: #{post.title}"
    end
    
    imported_ids
  end

  def import_case_studies
    log "📊 Importing case studies..."
    imported_ids = []
    
    case_studies = [
      {
        title: "Dropbox Keeping Flow",
        file: "app/views/works/_dropbox_keeping_flow.html.erb",
        category: "Case Study"
      },
      {
        title: "Mayo Clinic Gamifying Medical Education", 
        file: "app/views/works/_mayo_gamifying_medical_education.html.erb",
        category: "Case Study"
      },
      {
        title: "We Ate The Web Saving Money",
        file: "app/views/works/_we_ate_the_web_saving_money.html.erb", 
        category: "Case Study"
      }
    ]
    
    case_studies.each do |study|
      next unless File.exist?(study[:file])
      
      content = File.read(study[:file])
      # Strip HTML tags and clean up content
      clean_content = ActionView::Base.full_sanitizer.sanitize(content)
      
      knowledge_item = KnowledgeItem.find_or_initialize_by(
        title: study[:title],
        source: study[:file]
      )
      
      knowledge_item.assign_attributes(
        content: clean_content,
        category: study[:category],
        confidence_score: 0.95,
        last_updated: File.mtime(study[:file])
      )
      
      knowledge_item.save!
      imported_ids << knowledge_item.id
      log "  ✅ Imported case study: #{study[:title]}"
    end
    
    imported_ids
  end

  private

  def queue_chunk_generation(knowledge_item_ids)
    return if knowledge_item_ids.empty?
    
    log "🧩 Queueing chunk generation for #{knowledge_item_ids.count} knowledge items..."
    
    knowledge_item_ids.each do |id|
      GenerateChunksJob.perform_later(id)
    end
  end

  def log(message)
    puts message unless Rails.env.test?
  end


end
