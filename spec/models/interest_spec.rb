require "rails_helper"

RSpec.describe Interest do
  it { should have_and_belong_to_many :followers }
end
