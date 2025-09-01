namespace :knowledge do
  desc "Import all published posts and case studies into the database"
  task import: :environment do
    puts "Starting comprehensive knowledge base import..."
    
    service = KnowledgeImportService.new
    result = service.import_all
    
    if result
      count = KnowledgeItem.count
      puts "✅ Successfully imported knowledge base!"
      puts "📊 Total knowledge items: #{count}"
      
      # Show categories
      categories = KnowledgeItem.group(:category).count
      puts "\n📁 Categories:"
      categories.each do |category, count|
        puts "  - #{category}: #{count} items"
      end
    else
      puts "❌ Import failed. Check logs for details."
    end
  end



  desc "Import only published posts"
  task import_posts: :environment do
    puts "Starting posts import..."
    
    service = KnowledgeImportService.new
    service.import_published_posts
    
    count = KnowledgeItem.where(category: 'Blog Post').count
    puts "✅ Successfully imported #{count} published posts!"
  end

  desc "Import only case studies"
  task import_case_studies: :environment do
    puts "Starting case studies import..."
    
    service = KnowledgeImportService.new
    service.import_case_studies
    
    count = KnowledgeItem.where(category: 'Case Study').count
    puts "✅ Successfully imported #{count} case studies!"
  end

  desc "Clear all knowledge items from the database"
  task clear: :environment do
    puts "Clearing all knowledge items..."
    count = KnowledgeItem.count
    KnowledgeItem.destroy_all
    puts "✅ Cleared #{count} knowledge items"
  end

  desc "Show statistics about the knowledge base"
  task stats: :environment do
    total = KnowledgeItem.count
    categories = KnowledgeItem.group(:category).count
    avg_confidence = KnowledgeItem.average(:confidence_score)
    
    puts "📊 Knowledge Base Statistics"
    puts "=========================="
    puts "Total items: #{total}"
    puts "Categories: #{categories.keys.join(', ')}"
    puts "Average confidence: #{avg_confidence&.round(2) || 'N/A'}"
    
    puts "\n📁 Items by category:"
    categories.each do |category, count|
      puts "  #{category}: #{count}"
    end
  end
end
