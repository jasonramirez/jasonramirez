FactoryGirl.define do
  factory :admin do
    email "admin@example.com"
    password "password"
  end

  factory :post do
    title "Post"
    body "This is a great post."
    published true
    published_date "2016-07-19 07:34:28"
  end

  factory :interest do
  end

  factory :follower do
  end
end
