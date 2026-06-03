require "rails_helper"

RSpec.describe "API and Special routes", type: :routing do
  describe "JSON feed route" do
    it "routes GET /feed.json to posts#feed" do
      expect(get: "/feed.json").to route_to(controller: "posts", action: "feed")
    end
  end

  describe "sitemap routes" do
    it "routes GET /sitemap.xml to sitemaps#show" do
      expect(get: "/sitemap.xml").to route_to(controller: "sitemaps", action: "show")
    end
  end
end
