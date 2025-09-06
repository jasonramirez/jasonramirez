require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  describe "GET #feed" do
    let!(:published_post) do
      create(:post, 
        title: "Test Published Post",
        post_markdown: "# Test Content\n\nThis is **bold** text.",
        post_text: "Test Content This is bold text.",
        summary: "A test post summary",
        published: true,
        published_date: 2.days.ago
      )
    end
    
    let!(:unpublished_post) do
      create(:post,
        title: "Test Unpublished Post", 
        published: false
      )
    end
    
    let!(:newer_post) do
      create(:post,
        title: "Newer Published Post",
        post_text: "Newer content",
        published: true,
        published_date: 1.day.ago
      )
    end

    before { get :feed, format: :json }

    describe "response" do
      it "responds successfully" do
        expect(response).to have_http_status(:success)
      end

      it "returns JSON content type" do
        expect(response.content_type).to include('application/json')
      end

      it "returns valid JSON" do
        expect { JSON.parse(response.body) }.not_to raise_error
      end
    end

    describe "feed structure" do
      let(:feed_data) { JSON.parse(response.body) }

      it "includes required feed metadata" do
        expect(feed_data['version']).to eq('https://jsonfeed.org/version/1.1')
        expect(feed_data['title']).to eq('Jason Ramirez - Blog Posts')
        expect(feed_data['description']).to include('Jason Ramirez')
        expect(feed_data['copyright']).to include('Jason Ramirez')
        expect(feed_data['license']).to include('link back')
      end

      it "includes author information" do
        author = feed_data['author']
        expect(author['name']).to eq('Jason Ramirez')
        expect(author['bio']).to eq('Product Design Leader')
        expect(author['url']).to be_present
      end

      it "includes home_page_url and feed_url" do
        expect(feed_data['home_page_url']).to be_present
        expect(feed_data['feed_url']).to include('/feed.json')
      end
    end

    describe "post filtering and ordering" do
      let(:feed_data) { JSON.parse(response.body) }
      let(:items) { feed_data['items'] }

      it "only includes published posts" do
        titles = items.map { |item| item['title'] }
        expect(titles).to include('Test Published Post', 'Newer Published Post')
        expect(titles).not_to include('Test Unpublished Post')
      end

      it "orders posts by published_date descending (newest first)" do
        expect(items.first['title']).to eq('Newer Published Post')
        expect(items.second['title']).to eq('Test Published Post')
      end
    end

    describe "post content" do
      let(:feed_data) { JSON.parse(response.body) }
      let(:first_item) { feed_data['items'].first }

      it "includes all required post fields" do
        expect(first_item['id']).to be_present
        expect(first_item['url']).to be_present
        expect(first_item['external_url']).to be_present
        expect(first_item['title']).to be_present
        expect(first_item['content_text']).to be_present
        expect(first_item['content_html']).to be_present
        expect(first_item['date_published']).to be_present
        expect(first_item['date_modified']).to be_present
      end

      it "includes proper attribution" do
        expect(first_item['authors']).to be_an(Array)
        expect(first_item['authors'].first['name']).to eq('Jason Ramirez')
        expect(first_item['attribution']).to include('Originally published at')
      end

      it "formats dates in ISO8601" do
        expect(first_item['date_published']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
        expect(first_item['date_modified']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      end

      it "includes URL fields pointing to the post" do
        post_url_pattern = /\/posts\/.*$/
        expect(first_item['id']).to match(post_url_pattern)
        expect(first_item['url']).to match(post_url_pattern)
        expect(first_item['external_url']).to match(post_url_pattern)
      end
    end

    describe "post content accuracy" do
      let(:feed_data) { JSON.parse(response.body) }
      let(:test_post_item) do
        feed_data['items'].find { |item| item['title'] == 'Test Published Post' }
      end

      it "matches post model data" do
        expect(test_post_item['title']).to eq(published_post.title)
        expect(test_post_item['content_text']).to eq(published_post.post_text)
        expect(test_post_item['summary']).to eq(published_post.summary)
      end

      it "includes hashtags as tags" do
        published_post.hashtags << create(:hashtag, label: 'design')
        published_post.hashtags << create(:hashtag, label: 'leadership')
        
        get :feed, format: :json
        feed_data = JSON.parse(response.body)
        test_item = feed_data['items'].find { |item| item['title'] == 'Test Published Post' }
        
        expect(test_item['tags']).to include('#design', '#leadership')
      end
    end
  end
end
