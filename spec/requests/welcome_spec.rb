require "rails_helper"

RSpec.describe "Welcome", type: :request do
  describe "GET /" do
    it "returns a successful response" do
      get root_path
      expect(response).to be_successful
    end

    it "returns correct content type" do
      get root_path
      expect(response.content_type).to include("text/html")
    end

    it "contains expected content" do
      get root_path
      expect(response.body).to include("html")
    end
  end

  describe "GET /index (via root)" do
    it "returns a successful response" do
      get "/"
      expect(response).to be_successful
    end
  end
end
