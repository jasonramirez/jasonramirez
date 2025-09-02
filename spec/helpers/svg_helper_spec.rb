require 'rails_helper'

RSpec.describe SvgHelper, type: :helper do
  describe '#inline_svg' do
    it 'returns SVG content when file exists' do
      result = helper.inline_svg('icon-checkmark.svg')
      expect(result).to include('<svg')
      expect(result).to include('viewBox')
    end

    it 'applies class option' do
      result = helper.inline_svg('icon-checkmark.svg', class: 'test-class')
      expect(result).to include('class="test-class"')
    end

    it 'applies height and width options' do
      result = helper.inline_svg('icon-trashcan.svg', height: '12', width: '12')
      expect(result).to include('width="12"')
      expect(result).to include('height="12"')
      # Should not contain the original 24x24 values
      expect(result).to_not include('width="24"')
      expect(result).to_not include('height="24"')
    end

    it 'overrides existing width and height attributes' do
      result = helper.inline_svg('icon-trashcan.svg', height: '16', width: '16')
      expect(result).to include('width="16"')
      expect(result).to include('height="16"')
      expect(result).to_not include('width="24"')
      expect(result).to_not include('height="24"')
    end

    it 'returns comment when file does not exist' do
      result = helper.inline_svg('nonexistent.svg')
      expect(result).to include('SVG not found')
    end
  end

  describe '#inline_svg_tag' do
    it 'is an alias for inline_svg' do
      expect(helper.inline_svg_tag('icon-checkmark.svg')).to eq(
        helper.inline_svg('icon-checkmark.svg')
      )
    end
  end
end
