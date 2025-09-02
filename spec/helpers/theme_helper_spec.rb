require 'rails_helper'

RSpec.describe ThemeHelper, type: :helper do
  describe '#theme' do
    it 'returns dark theme by default' do
      # Clear any existing theme cookie
      helper.request.cookies.delete(:theme)
      
      expect(helper.send(:theme)).to eq('dark')
    end

    it 'returns stored theme from cookies' do
      helper.request.cookies[:theme] = 'light'
      
      expect(helper.send(:theme)).to eq('light')
    end
  end

  describe '#theme_color' do
    it 'returns dark theme color for dark theme' do
      helper.request.cookies[:theme] = 'dark'
      
      expect(helper.send(:theme_color)).to eq('#181923')
    end

    it 'returns light theme color for light theme' do
      helper.request.cookies[:theme] = 'light'
      
      expect(helper.send(:theme_color)).to eq('#fffaed')
    end
  end

  describe '#theme_stylesheet' do
    it 'returns dark theme stylesheet for dark theme' do
      helper.request.cookies[:theme] = 'dark'
      
      expect(helper.theme_stylesheet).to eq('application_dark')
    end

    it 'returns light theme stylesheet for light theme' do
      helper.request.cookies[:theme] = 'light'
      
      expect(helper.theme_stylesheet).to eq('application_light')
    end
  end

  describe '#theme_content' do
    it 'returns theme color' do
      helper.request.cookies[:theme] = 'dark'
      
      expect(helper.theme_content).to eq('#181923')
    end
  end

  describe '#stylesheet' do
    it 'generates stylesheet link tag' do
      helper.request.cookies[:theme] = 'dark'
      
      result = helper.stylesheet
      expect(result).to include('application_dark')
      # The stylesheet method returns the actual HTML, not the method name
      expect(result).to include('rel="stylesheet"')
    end
  end
end
