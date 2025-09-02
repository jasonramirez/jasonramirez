require 'rails_helper'

RSpec.describe Hashtag, type: :model do
  describe "validations" do
    it { should validate_presence_of(:label) }
    it { should validate_uniqueness_of(:label).case_insensitive }
  end

  describe "associations" do
    it { should have_many(:post_hashtags).dependent(:destroy) }
    it { should have_many(:posts).through(:post_hashtags) }
  end

  describe "scopes" do
    let!(:hashtag1) { create(:hashtag, label: "ruby") }
    let!(:hashtag2) { create(:hashtag, label: "rails") }
    let!(:hashtag3) { create(:hashtag, label: "javascript") }

    describe ".ordered_by_label" do
      it "orders hashtags alphabetically by label" do
        expect(Hashtag.ordered_by_label.first).to eq(hashtag3) # javascript
        expect(Hashtag.ordered_by_label.last).to eq(hashtag2)  # rails
      end
    end
  end

  describe "methods" do
    let(:hashtag) { create(:hashtag, label: "Ruby on Rails") }

    describe "#slug" do
      it "generates a URL-friendly slug from label" do
        expect(hashtag.slug).to eq("ruby-on-rails")
      end
    end

    describe "#display_name" do
      it "returns the label as display name" do
        expect(hashtag.display_name).to eq("Ruby on Rails")
      end
    end
  end

  describe "search functionality" do
    let!(:hashtag1) { create(:hashtag, label: "Ruby on Rails") }
    let!(:hashtag2) { create(:hashtag, label: "JavaScript") }
    let!(:hashtag3) { create(:hashtag, label: "CSS") }

    describe ".search_by_label" do
      it "finds hashtags by label" do
        results = Hashtag.search_by_label("Ruby")
        expect(results).to include(hashtag1)
        expect(results).to_not include(hashtag2, hashtag3)
      end

      it "is case insensitive" do
        results = Hashtag.search_by_label("ruby")
        expect(results).to include(hashtag1)
      end
    end
  end
end
