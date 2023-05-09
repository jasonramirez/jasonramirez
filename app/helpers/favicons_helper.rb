module FaviconsHelper
  def favicon(href:, rel:, size:)
    return favicon_link_tag filename(href, size),
      rel: rel,
      sizes: sizes(size),
      type: type
  end

  def filename(type, size)
    "favicons/#{type}-#{sizes(size)}.png"
  end

  def sizes(size)
    "#{size}x#{size}"
  end

  def type
    "image/png"
  end
end
