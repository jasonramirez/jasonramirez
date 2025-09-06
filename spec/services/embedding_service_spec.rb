require 'rails_helper'

RSpec.describe EmbeddingService, type: :service do
  let(:service) { EmbeddingService.new }
  
  describe "#generate_embedding" do
    context "with valid text" do
      let(:mock_response) do
        {
          "data" => [
            {
              "embedding" => Array.new(1536) { rand(-1.0..1.0) }
            }
          ]
        }
      end
      
      before do
        # Mock the OpenAI client
        client = double("OpenAI::Client")
        allow(OpenAI::Client).to receive(:new).and_return(client)
        allow(client).to receive(:embeddings).and_return(mock_response)
      end
      
      it "returns an embedding array" do
        result = service.generate_embedding("Test text for embedding")
        
        expect(result).to be_an(Array)
        expect(result.length).to eq(1536)
        expect(result.all? { |val| val.is_a?(Numeric) }).to be true
      end
      
      it "calls OpenAI API with correct parameters" do
        client = double("OpenAI::Client")
        allow(OpenAI::Client).to receive(:new).and_return(client)
        expect(client).to receive(:embeddings).with(
          parameters: {
            model: "text-embedding-3-small",
            input: "Test text"
          }
        ).and_return(mock_response)
        
        service.generate_embedding("Test text")
      end
    end
    
    context "with blank text" do
      it "returns nil for empty string" do
        result = service.generate_embedding("")
        expect(result).to be_nil
      end
      
      it "returns nil for nil input" do
        result = service.generate_embedding(nil)
        expect(result).to be_nil
      end
    end
    
    context "when OpenAI API fails" do
      before do
        client = double("OpenAI::Client")
        allow(OpenAI::Client).to receive(:new).and_return(client)
        allow(client).to receive(:embeddings).and_raise(OpenAI::Error.new("API Error"))
      end
      
      it "logs error and returns nil" do
        expect(Rails.logger).to receive(:error).with(/Embedding generation error/)
        
        result = service.generate_embedding("Test text")
        expect(result).to be_nil
      end
    end
    
    context "when response format is unexpected" do
      before do
        client = double("OpenAI::Client")
        allow(OpenAI::Client).to receive(:new).and_return(client)
        allow(client).to receive(:embeddings).and_return({ "data" => [] })
      end
      
      it "logs error and returns nil" do
        expect(Rails.logger).to receive(:error).with(/Embedding generation error/)
        
        result = service.generate_embedding("Test text")
        expect(result).to be_nil
      end
    end
  end
  
  describe "configuration" do
    context "when OpenAI API key is not configured" do
      before do
        allow(Rails.application.credentials).to receive(:openai_api_key).and_return(nil)
        # Mock WebMock to avoid HTTP connection issues
        stub_request(:any, /api.openai.com/).to_return(status: 200, body: "", headers: {})
      end
      
      it "raises configuration error" do
        expect(Rails.logger).to receive(:error).with(/OpenAI API key not configured/)
        result = service.generate_embedding("test")
        expect(result).to be_nil
      end
    end
  end
end
