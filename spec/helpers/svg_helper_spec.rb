require 'rails_helper'

RSpec.describe SvgHelper, type: :helper do
  describe '#inline_svg' do
    it 'returns SVG content when file exists' do
      # Create a temporary SVG file for testing
      svg_path = Rails.root.join('app/assets/images/test.svg')
      File.write(svg_path, '<svg class="test">Test SVG</svg>')
      
      result = helper.inline_svg('test.svg')
      expect(result).to include('Test SVG')
      expect(result).to include('<svg class="test">')
      
      # Clean up
      File.delete(svg_path)
    end

    it 'returns comment when file does not exist' do
      result = helper.inline_svg('nonexistent.svg')
      expect(result).to include('<!-- SVG not found: nonexistent.svg -->')
    end

    it 'applies height and width options' do
      svg_path = Rails.root.join('app/assets/images/test.svg')
      File.write(svg_path, '<svg>Test SVG</svg>')
      
      result = helper.inline_svg('test.svg', height: '24', width: '24')
      expect(result).to include('height="24"')
      expect(result).to include('width="24"')
      
      File.delete(svg_path)
    end

    it 'applies class option' do
      svg_path = Rails.root.join('app/assets/images/test.svg')
      File.write(svg_path, '<svg>Test SVG</svg>')
      
      result = helper.inline_svg('test.svg', class: 'test-class')
      expect(result).to include('class="test-class"')
      
      File.delete(svg_path)
    end
  end

  describe '#inline_svg_tag' do
    it 'is an alias for inline_svg' do
      svg_path = Rails.root.join('app/assets/images/test.svg')
      File.write(svg_path, '<svg>Test SVG</svg>')
      
      result1 = helper.inline_svg('test.svg', class: 'test')
      result2 = helper.inline_svg_tag('test.svg', class: 'test')
      
      expect(result1).to eq(result2)
      
      File.delete(svg_path)
    end
  end
end
