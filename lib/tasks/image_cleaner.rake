namespace :image_cleaner do
  desc "Find and remove unused impages"
  task find_unused_images: :environment do
    images = Dir.glob("app/assets/images/**/*")
    unused_images = []

    images.each do |image|
      unless File.directory?(image)
        puts "Checking #{image}..."

        result = `grep -nr #{File.basename(image)}* app/`

        if result.empty?
          unused_images << image

          puts "Deleteing unused image #{image}"

          `rm -rf #{image}`
        end
      end
    end
  end
end
