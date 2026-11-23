require "rails_helper"

RSpec.describe "Health check", type: :request do
  describe "GET /up" do
    it "returns a successful response" do
      get rails_health_check_path
      expect(response).to be_successful
    end
  end
end
