FactoryBot.define do
  factory :post_tag do
    text { "MyString" }
  end

  factory :tag do
    lable { "MyString" }
  end

  factory :admin do
    email { "admin@example.com" }
    password { "password" }
  end

  factory :post do
    title { "Post" }
    summary { "This is the summary of the post." }
    body { "This is a great post." }
    tldr_transcript { "This is the TLDR transcript of the post." }
    published { true }
    published_date { "2016-07-19 07:34:28" }
  end

  factory :post_with_hashtag, :parent => :post do |post|
    hashtags { build_list :hashtag, 2 }
  end

  factory :hashtag do
    label { "hashtag" }
  end

  factory :interest do
  end

  factory :follower do
  end

  factory :chat_user do
    name { "Test User" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    approved { true }
    login_expires_at { 48.hours.from_now }
    
    # Don't set password for traits that shouldn't trigger encryption
    trait :without_expiration do
      login_expires_at { nil }
    end
  end

  factory :chat_message do
    association :chat_user
    content { "Hello, this is a test message." }
    message_type { "user" }
  end
end
