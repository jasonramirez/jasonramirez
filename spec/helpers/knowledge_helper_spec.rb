require 'rails_helper'

RSpec.describe KnowledgeHelper, type: :helper do
  describe '#read_transcript_file' do
    it 'returns formatted transcript content when file exists' do
      # Create a temporary transcript file for testing
      transcript_path = Rails.root.join('app/assets/transcripts/test.txt')
      File.write(transcript_path, "Paragraph 1\n\nParagraph 2\n\nParagraph 3")
      
      result = helper.read_transcript_file('transcripts/test.txt')
      expect(result).to include('<p>Paragraph 1</p>')
      expect(result).to include('<p>Paragraph 2</p>')
      expect(result).to include('<p>Paragraph 3</p>')
      
      # Clean up
      File.delete(transcript_path)
    end

    it 'returns nil when file does not exist' do
      result = helper.read_transcript_file('nonexistent.txt')
      expect(result).to be_nil
    end

    it 'handles empty paragraphs' do
      transcript_path = Rails.root.join('app/assets/transcripts/test.txt')
      File.write(transcript_path, "Paragraph 1\n\n\n\nParagraph 2")
      
      result = helper.read_transcript_file('transcripts/test.txt')
      expect(result).to include('<p>Paragraph 1</p>')
      expect(result).to include('<p>Paragraph 2</p>')
      
      File.delete(transcript_path)
    end
  end

  describe '#render_knowledge_sources' do
    it 'returns nil when no sources exist' do
      result = helper.render_knowledge_sources(nil)
      expect(result).to be_nil
    end

    it 'returns nil when sources array is empty' do
      result = helper.render_knowledge_sources({ 'sources' => [] })
      expect(result).to be_nil
    end

    it 'filters public sources correctly' do
      # This test would need more setup with actual Post models
      # For now, we'll test the basic structure
      kb_data = { 'sources' => [{ 'category' => 'Blog Post', 'title' => 'Test Post' }] }
      
      # Mock the render method since we're testing a helper
      allow(helper).to receive(:render).and_return('rendered content')
      
      # Mock the filter_public_sources method to return a non-empty array
      allow(helper).to receive(:filter_public_sources).and_return([{ 'category' => 'Blog Post', 'title' => 'Test Post' }])
      
      result = helper.render_knowledge_sources(kb_data)
      expect(result).to eq('rendered content')
    end
  end

  describe '#source_link_url' do
    it 'returns post path for blog post sources' do
      # This would need a factory or mock Post model
      # For now, we'll test the basic logic
      source = { 'category' => 'Blog Post', 'title' => 'Test Post' }
      
      # Mock Post.find_by to return a mock post
      mock_post = double('Post', id: 1)
      allow(Post).to receive(:where).and_return(double(find_by: mock_post))
      allow(helper).to receive(:post_path).and_return('/posts/1')
      
      result = helper.send(:source_link_url, source)
      expect(result).to eq('/posts/1')
    end

    it 'returns works path for case study sources' do
      source = { 'category' => 'Case Study', 'title' => 'Test Case Study' }
      
      result = helper.send(:source_link_url, source)
      expect(result).to eq('/works/test_case_study')
    end

    it 'handles special characters in case study titles' do
      source = { 'category' => 'Case Study', 'title' => 'Test & Case Study (2023)' }
      
      result = helper.send(:source_link_url, source)
      expect(result).to eq('/works/test_case_study_2023')
    end
  end
end
