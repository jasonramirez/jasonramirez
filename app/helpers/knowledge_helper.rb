module KnowledgeHelper
  def read_transcript_file(file_path)
    full_path = Rails.root.join('app', 'assets', file_path)
    return nil unless File.exist?(full_path)
    
    content = File.read(full_path)
    paragraphs = content.split(/\n\s*\n/).reject(&:blank?)
    
    paragraphs.map do |paragraph|
      content_tag(:p, paragraph.strip)
    end.join.html_safe
  end

  def render_knowledge_sources(kb_data)
    return unless kb_data&.dig('sources')&.any?
    
    public_sources = filter_public_sources(kb_data['sources'])
    return unless public_sources.any?
    
    render partial: 'jason_ai/sources', locals: { 
      sources: public_sources, 
      count: public_sources.count 
    }
  end

  private

  def filter_public_sources(sources)
    # Preload all blog post titles to avoid N+1 queries
    blog_post_titles = sources.select { |s| s['category'] == 'Blog Post' }.map { |s| s['title'] }
    blog_posts = Post.where(published: true, title: blog_post_titles).index_by(&:title)
    
    sources.select do |source|
      case source['category']
      when 'Blog Post'
        blog_posts[source['title']].present?
      when 'Case Study'
        source['title'].present? # All case studies are public
      else
        false
      end
    end
  end

  def source_link_url(source)
    case source['category']
    when 'Blog Post'
      post = Post.where(published: true).find_by(title: source['title'])
      post ? post_path(post) : nil
    when 'Case Study'
      # Convert title to URL-friendly format
      title_slug = source['title'].downcase.gsub(/[^a-z0-9\s]/, '').gsub(/\s+/, '_')
      "/works/#{title_slug}"
    end
  end
end
