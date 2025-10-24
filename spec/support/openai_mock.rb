# Mock OpenAI services for testing
RSpec.configure do |config|
  config.before(:each) do
    # Mock OpenAI API key for tests - only provide default if not explicitly set
    allow(ENV).to receive(:[]).and_call_original
    # Only mock if the key is not explicitly set to nil in the test
    unless ENV['OPENAI_API_KEY'].nil?
      allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return(ENV['OPENAI_API_KEY'] || 'test-key-for-ci')
    end
    
    # Mock OpenAI API responses
    if defined?(OpenAI)
      allow_any_instance_of(OpenAI::Client).to receive(:embeddings).and_return(
        {
          'data' => [
            {
              'embedding' => Array.new(3072) { rand(-1.0..1.0) }
            }
          ]
        }
      )
      
      allow_any_instance_of(OpenAI::Client).to receive(:chat).and_return(
        {
          'choices' => [
            {
              'message' => {
                'content' => 'Mocked AI response for testing'
              }
            }
          ]
        }
      )
    end
  end
end
