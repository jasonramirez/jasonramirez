require 'rails_helper'

RSpec.describe Admins::AdditionalKnowledgesHelper, type: :helper do
  describe 'helper methods' do
    it 'is available' do
      expect(helper).to be_present
    end

    it 'includes the helper module' do
      expect(helper.class.ancestors).to include(Admins::AdditionalKnowledgesHelper)
    end
  end
end
