require 'rails_helper'

RSpec.describe Hashtag, type: :model do
  it { should validate_presence_of(:label) }
end
