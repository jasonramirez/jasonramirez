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
          # Always replace the class attribute
          svg_tag.gsub!(/\bclass="[^"]*"/, "class=\"#{value}\"")
          # If no class was found, add one
          unless svg_tag.include?('class="')
            svg_tag.gsub!(/>$/, " class=\"#{value}\">")
          end
        when :style
          if svg_tag.include?('style="')
            svg_tag.gsub!(/\bstyle="([^"]*)"/, "style=\"\\1 #{value}\"")
          else
            svg_tag.gsub!(/>$/, " style=\"#{value}\">")
          end
        when :height, :width
          # Use precise pattern to match exact attribute names
          svg_tag.gsub!(/(?<=\s|^)#{key}="[^"]*"/, "#{key}=\"#{value}\"")
          # If no attribute was found, add one
          unless svg_tag.include?("#{key}=\"")
            svg_tag.gsub!(/>$/, " #{key}=\"#{value}\">")
          end
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
