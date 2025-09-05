namespace :sitemap do
  desc "Ping search engines about sitemap updates"
  task ping: :environment do
    sitemap_url = "https://www.jasonramirez.com/sitemap.xml"
    
    search_engines = [
      "https://www.google.com/ping?sitemap=#{sitemap_url}",
      "https://www.bing.com/ping?sitemap=#{sitemap_url}"
    ]
    
    search_engines.each do |ping_url|
      begin
        response = Net::HTTP.get_response(URI(ping_url))
        if response.code == "200"
          puts "✓ Successfully pinged #{ping_url}"
        else
          puts "✗ Failed to ping #{ping_url} - Status: #{response.code}"
        end
      rescue => e
        puts "✗ Error pinging #{ping_url}: #{e.message}"
      end
    end
  end
  
  desc "Show sitemap stats"
  task stats: :environment do
    posts_count = Post.where(published: true).count
    puts "Sitemap contains #{posts_count} published posts"
    puts "Last updated post: #{Post.where(published: true).order(updated_at: :desc).first&.updated_at}"
  end
end
