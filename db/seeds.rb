puts "🌱 Seeding database..." unless Rails.env.test?

# Create admin user
admin = Admin.create!(
  email: 'jason+admin@jasonramirez.com',
  password: 'password'
)
puts "✅ Created admin: #{admin.email}" unless Rails.env.test?

# Create chat user
chat_user = ChatUser.create!(
  name: 'Jason Ramirez',
  email: 'jason+my-mind@jasonramirez.com',
  password: 'password',
  approved: true
)
puts "✅ Created chat user: #{chat_user.email}" unless Rails.env.test?

puts "🎉 Seeding complete!" unless Rails.env.test?
