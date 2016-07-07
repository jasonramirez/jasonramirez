require "rails_helper"

RSpec.describe Follower do
  it { should validate_presence_of :email }

  it { should have_and_belong_to_many :interests }
end
