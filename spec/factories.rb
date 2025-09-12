FactoryBot.define do
  factory :additional_knowledge do
    title { "MyString" }
    content { "MyText" }
    category { "MyString" }
    priority { 1 }
  end

  factory :knowledge_chunk do
    association :knowledge_item
    content { "This is sample chunk content about design principles and best practices." }
    chunk_index { 0 }
    chunk_type { "semantic" }
    title { "Sample Knowledge Chunk" }
    category { "Blog Post" }
    tags { "#design, #principles, #process" }
    confidence_score { 0.9 }
    source { "post_123" }
    last_updated { 1.day.ago }
  end

  factory :knowledge_item do
    title { "Sample Knowledge Item" }
    content { "This is sample content for testing knowledge base functionality." }
    category { "Blog Post" }
    tags { "#design, #process" }
    source { "post_123" }
    confidence_score { 0.9 }
  end

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
    post_markdown { "This is a **great** post with *markdown*." }
    post_text { "This is a great post with markdown." }
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
    email { "test#{SecureRandom.hex(8)}@example.com" }
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
    message_type { "question" }
    
    trait :answer do
      message_type { "answer" }
      content { "This is a response from the AI assistant." }
    end
    
    trait :with_embedding do
      after(:create) do |message|
        # Create a valid 1536-dimension embedding
        embedding = Array.new(1536, 0.1)
        # Skip embedding update for now due to pgvector type issues
        # message.update_column(:content_embedding, "[#{embedding.join(',')}]")
      end
    end
  end
end
