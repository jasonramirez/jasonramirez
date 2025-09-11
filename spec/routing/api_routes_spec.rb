require "rails_helper"

RSpec.describe "API and Special routes", type: :routing do
  describe "JSON feed route" do
    it "routes GET /feed.json to posts#feed" do
      expect(get: "/feed.json").to route_to(controller: "posts", action: "feed")
    end
  end

  describe "chat authentication routes" do
    it "routes DELETE /chat/logout to chat_auth#logout" do
      expect(delete: "/chat/logout").to route_to(controller: "chat_auth", action: "logout")
    end

    it "routes GET /chat/login to chat_auth#login" do
      expect(get: "/chat/login").to route_to(controller: "chat_auth", action: "login")
    end

    it "routes POST /chat/login to chat_auth#login" do
      expect(post: "/chat/login").to route_to(controller: "chat_auth", action: "login")
    end

    it "routes GET /chat/register to chat_auth#register" do
      expect(get: "/chat/register").to route_to(controller: "chat_auth", action: "register")
    end

    it "routes POST /chat/register to chat_auth#register" do
      expect(post: "/chat/register").to route_to(controller: "chat_auth", action: "register")
    end
  end

  describe "JasonAI routes" do
    it "routes GET /jason_ai to jason_ai#index" do
      expect(get: "/jason_ai").to route_to(controller: "jason_ai", action: "index")
    end

    it "routes POST /jason_ai/ask to jason_ai#ask" do
      expect(post: "/jason_ai/ask").to route_to(controller: "jason_ai", action: "ask")
    end

    it "routes POST /jason_ai/render_message to jason_ai#render_message" do
      expect(post: "/jason_ai/render_message").to route_to(controller: "jason_ai", action: "render_message")
    end

    it "routes POST /jason_ai/feedback to jason_ai#feedback" do
      expect(post: "/jason_ai/feedback").to route_to(controller: "jason_ai", action: "feedback")
    end

    it "routes GET /jason_ai/check_audio/:question_hash to jason_ai#check_audio" do
      expect(get: "/jason_ai/check_audio/abc123").to route_to(
        controller: "jason_ai", 
        action: "check_audio", 
        question_hash: "abc123"
      )
    end
  end

  describe "sitemap routes" do
    it "routes GET /sitemap.xml to sitemaps#show" do
      expect(get: "/sitemap.xml").to route_to(controller: "sitemaps", action: "show")
    end
  end
end
