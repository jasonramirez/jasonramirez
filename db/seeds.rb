puts "🌱 Seeding database..."

# Create admin user
admin = Admin.create!(
  email: 'jason+admin@jasonramirez.com',
  password: 'password'
)
puts "✅ Created admin: #{admin.email}"

# Create chat user
chat_user = ChatUser.create!(
  name: 'Jason Ramirez',
  email: 'jason+my-mind@jasonramirez.com',
  password: 'password',
  approved: true
)
puts "✅ Created chat user: #{chat_user.email}"

puts "🎉 Seeding complete!"
