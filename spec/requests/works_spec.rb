require "rails_helper"

RSpec.describe "Works", type: :request do
  describe "GET /works" do
    it "returns a successful response" do
      get works_path
      expect(response).to be_successful
    end

    it "returns correct content type" do
      get works_path
      expect(response.content_type).to include("text/html")
    end

    it "shows case studies" do
      get works_path
      expect(response.body).to include("html")
    end
  end
end
