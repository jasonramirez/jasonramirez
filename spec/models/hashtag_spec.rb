require 'rails_helper'

RSpec.describe Hashtag, type: :model do
  describe "validations" do
    it { should validate_presence_of(:label) }
    it { should validate_uniqueness_of(:label).case_insensitive }
  end

  describe "associations" do
    it { should have_and_belong_to_many(:posts) }
  end
end
