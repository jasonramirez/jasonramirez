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
    long_title { "Long Post Title" }
    body { "This is a great post." }
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
end
