module ApplicationHelper
  def theme_content
    theme_color
  end

  def stylesheet
    stylesheet_link_tag(
      theme_stylesheet,
      media: "all",
      "data-turbo-track": Rails.env.production? ? "reload" : ""
    )
  end

  def theme_stylesheet
    "application_#{theme}"
  end

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
    
    render partial: 'my_mind/sources', locals: { 
      sources: public_sources, 
      count: public_sources.count 
    }
  end

  private

  def theme
    cookies[:theme] ||= "dark"
  end

  def theme_color
    theme == "dark" ? "#181923" : "#fffaed"
  end

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

  # Propshaft-compatible SVG helper that reads SVG files and returns content inline
  def inline_svg(path, options = {})
    svg_path = Rails.root.join("app/assets/images", path)
    if File.exist?(svg_path)
      svg_content = File.read(svg_path)
      
      # Extract the SVG tag and apply options
      svg_tag = svg_content.match(/<svg[^>]*>/).to_s
      
      # Apply options to the SVG tag
      options.each do |key, value|
        case key
        when :class
          if svg_tag.include?('class="')
            svg_tag.gsub!(/class="([^"]*)"/, "class=\"\\1 #{value}\"")
          else
            svg_tag.gsub!(/>$/, " class=\"#{value}\">")
          end
        when :style
          if svg_tag.include?('style="')
            svg_tag.gsub!(/style="([^"]*)"/, "style=\"\\1 #{value}\"")
          else
            svg_tag.gsub!(/>$/, " style=\"#{value}\">")
          end
        when :height, :width
          svg_tag.gsub!(/>$/, " #{key}=\"#{value}\">")
        end
      end
      
      # Return the modified SVG content
      svg_content.gsub(/<svg[^>]*>/, svg_tag).html_safe
    else
      "<!-- SVG not found: #{path} -->".html_safe
    end
  end


end
