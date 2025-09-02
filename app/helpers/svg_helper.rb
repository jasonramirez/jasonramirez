module SvgHelper
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

  # Alias for inline_svg to match the view calls
  def inline_svg_tag(path, options = {})
    inline_svg(path, options)
  end
end
