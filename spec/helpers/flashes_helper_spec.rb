require 'rails_helper'

RSpec.describe FlashesHelper, type: :helper do
  describe '#user_facing_flashes' do
    it 'returns only user-facing flash types' do
      # Mock flash hash
      allow(helper).to receive(:flash).and_return({
        'alert' => 'Warning message',
        'error' => 'Error message', 
        'notice' => 'Success message',
        'other' => 'Hidden message'
      })

      result = helper.user_facing_flashes
      
      expect(result).to include('alert', 'error', 'notice')
      expect(result).to_not include('other')
    end
  end

  describe '#flash_icon' do
    it 'returns checkmark icon for notice' do
      result = helper.flash_icon('notice')
      expect(result).to include('<svg')
      expect(result).to include('viewBox')
    end

    it 'returns exclamation icon for alert' do
      result = helper.flash_icon('alert')
      expect(result).to include('<svg')
      expect(result).to include('viewBox')
    end

    it 'returns x icon for error' do
      result = helper.flash_icon('error')
      expect(result).to include('<svg')
      expect(result).to include('viewBox')
    end

    it 'returns info icon for unknown flash type' do
      result = helper.flash_icon('unknown')
      expect(result).to include('<svg')
      expect(result).to include('viewBox')
    end

    it 'calls inline_svg with correct icon name' do
      expect(helper).to receive(:inline_svg).with('icon-checkmark.svg')
      helper.flash_icon('notice')
    end
  end
end
