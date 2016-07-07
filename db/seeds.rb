interests_file = Rails.root.join("db", "seeds", "interests.yml")
interests = YAML::load_file(interests_file)

interests.each do |interest|
  Interest.first_or_create(interests)
end
