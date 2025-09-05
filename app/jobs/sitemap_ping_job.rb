class SitemapPingJob < ActiveJob::Base
  queue_as :default

  def perform
    sitemap_url = "https://www.jasonramirez.com/sitemap.xml"
    
    search_engines = [
      "https://www.google.com/ping?sitemap=#{sitemap_url}",
      "https://www.bing.com/ping?sitemap=#{sitemap_url}"
    ]
    
    search_engines.each do |ping_url|
      begin
        response = Net::HTTP.get_response(URI(ping_url))
        Rails.logger.info "Sitemap ping to #{ping_url}: #{response.code}"
      rescue => e
        Rails.logger.error "Failed to ping sitemap to #{ping_url}: #{e.message}"
      end
    end
  end
end
