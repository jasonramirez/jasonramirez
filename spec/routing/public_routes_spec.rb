require "rails_helper"

RSpec.describe "Public routes", type: :routing do
  describe "root route" do
    it "routes / to welcome#index" do
      expect(get: "/").to route_to(controller: "welcome", action: "index")
    end
  end

  describe "posts routes" do
    it "routes GET /posts to posts#index" do
      expect(get: "/posts").to route_to(controller: "posts", action: "index")
    end

    it "routes GET /posts/:id to posts#show" do
      expect(get: "/posts/123").to route_to(controller: "posts", action: "show", id: "123")
    end

    it "routes GET /posts/search to posts#search" do
      expect(get: "/posts/search").to route_to(controller: "posts", action: "search")
    end

    it "routes GET /feed.json to posts#feed" do
      expect(get: "/feed.json").to route_to(controller: "posts", action: "feed")
    end
  end

  describe "works routes" do
    it "routes GET /works to works#index" do
      expect(get: "/works").to route_to(controller: "works", action: "index")
    end

    it "routes GET /works/:work to works#show" do
      expect(get: "/works/sample-work").to route_to(controller: "works", action: "show", work: "sample-work")
    end
  end

  describe "protected works routes" do
    it "routes GET /protected_works/:protected_work to protected_works#show" do
      expect(get: "/protected_works/sample-case-study").to route_to(
        controller: "protected_works", 
        action: "show", 
        protected_work: "sample-case-study"
      )
    end
  end

  describe "followers routes" do
    it "routes GET /followers/new to followers#new" do
      expect(get: "/followers/new").to route_to(controller: "followers", action: "new")
    end

    it "routes POST /followers to followers#create" do
      expect(post: "/followers").to route_to(controller: "followers", action: "create")
    end
  end

  describe "password protection routes" do
    it "routes GET /password_protection/unlock to password_protection#unlock" do
      expect(get: "/password_protection/unlock").to route_to(
        controller: "password_protection", 
        action: "unlock"
      )
    end

    it "routes POST /password_protection/unlock to password_protection#unlock" do
      expect(post: "/password_protection/unlock").to route_to(
        controller: "password_protection", 
        action: "unlock"
      )
    end
  end

  describe "error routes" do
    it "routes /403 to errors#prohibited" do
      expect(get: "/403").to route_to(controller: "errors", action: "prohibited")
    end

    it "routes /404 to errors#not_found" do
      expect(get: "/404").to route_to(controller: "errors", action: "not_found")
    end

    it "routes /500 to errors#internal_server_error" do
      expect(get: "/500").to route_to(controller: "errors", action: "internal_server_error")
    end
  end

  describe "philosophy route" do
    it "routes GET /philosophy to philosophy#index" do
      expect(get: "/philosophy").to route_to(controller: "philosophy", action: "index")
    end
  end

  describe "privacy and terms route" do
    it "routes GET /privacy_and_terms to privacy_and_terms#index" do
      expect(get: "/privacy_and_terms").to route_to(controller: "privacy_and_terms", action: "index")
    end
  end
end
