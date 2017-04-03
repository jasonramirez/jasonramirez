require "rails_helper"

RSpec.describe Follower do
  it { should validate_presence_of :email }
end
