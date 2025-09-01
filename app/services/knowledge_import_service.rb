class KnowledgeImportService
  def initialize(directory_path = nil)
    @directory_path = directory_path || Rails.root.join('app', 'assets', 'knowledge')
  end

  def import_all
    puts "🌱 Starting comprehensive knowledge base import..."
    
    # Import published posts
    import_published_posts
    
    # Import case studies
    import_case_studies
    
    puts "✅ Knowledge base import complete!"
    puts "📊 Total knowledge items: #{KnowledgeItem.count}"
  end

  def import_published_posts
    puts "📝 Importing published posts..."
    
    Post.where(published: true).each do |post|
      knowledge_item = KnowledgeItem.find_or_initialize_by(
        title: post.title,
        source: "post_#{post.id}"
      )
      
      knowledge_item.assign_attributes(
        content: post.body,
        category: 'Blog Post',
        tags: post.hashtags.map(&:label).join(', '),
        confidence_score: 0.9,
        last_updated: post.updated_at
      )
      
      knowledge_item.save!
      puts "  ✅ Imported post: #{post.title}"
    end
  end

  def import_case_studies
    puts "📊 Importing case studies..."
    
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
      puts "  ✅ Imported case study: #{study[:title]}"
    end
  end


end
