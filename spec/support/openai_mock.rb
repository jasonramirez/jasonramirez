# Mock OpenAI services for testing
RSpec.configure do |config|
  config.before(:each) do
    # Mock OpenAI API key for tests (unless explicitly unset in test)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return(ENV['OPENAI_API_KEY'] || 'test-key-for-ci')
    
    # Mock OpenAI API responses
    if defined?(OpenAI)
      allow_any_instance_of(OpenAI::Client).to receive(:embeddings).and_return(
        {
          'data' => [
            {
              'embedding' => Array.new(1536) { rand(-1.0..1.0) }
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
