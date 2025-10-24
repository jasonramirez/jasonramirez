require "rails_helper"

# Skip VoiceService tests - ElevenLabs functionality removed
RSpec.describe VoiceService, skip: "Skipped - ElevenLabs gem removed" do
  let(:service) { described_class.new }
  let(:sample_text) { "Hello, this is a test message for voice generation." }
  let(:mock_client) { instance_double("Elevenlabs::Client") }
  let(:mock_response) { "mock_audio_data" }

  before do
    # Mock ElevenLabs client
    allow(::Elevenlabs::Client).to receive(:new).and_return(mock_client)
    
    # Set up environment variables with default fallback
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ELEVENLABS_API_KEY').and_return('test_api_key')
    allow(ENV).to receive(:[]).with('ELEVENLABS_DEFAULT_VOICE_ID').and_return('test_voice_id')
    
    # Mock file operations
    allow(service).to receive(:save_audio_file)
    allow(service).to receive(:audio_file_path).and_return('/path/to/audio.mp3')
  end

  describe "#initialize" do
    it "initializes with ElevenLabs client" do
      expect(::Elevenlabs::Client).to receive(:new).with(api_key: 'test_api_key')
      described_class.new
    end
  end

  describe "#generate_speech" do
    context "with valid inputs" do
      before do
        allow(mock_client).to receive(:text_to_speech).and_return(mock_response)
      end

      it "calls ElevenLabs API with correct parameters" do
        expect(mock_client).to receive(:text_to_speech).with(
          'test_voice_id',
          sample_text,
          model_id: 'eleven_monolingual_v1'
        )
        
        service.generate_speech(sample_text)
      end

      it "uses custom voice ID when provided" do
        custom_voice_id = 'custom_voice_123'
        expect(mock_client).to receive(:text_to_speech).with(
          custom_voice_id,
          sample_text,
          model_id: 'eleven_monolingual_v1'
        )
        
        service.generate_speech(sample_text, custom_voice_id)
      end

      it "saves audio file and returns file path" do
        expect(service).to receive(:save_audio_file).with(sample_text, mock_response)
        expect(service).to receive(:audio_file_path).with(sample_text).and_return('/path/to/audio.mp3')
        
        result = service.generate_speech(sample_text)
        expect(result).to eq('/path/to/audio.mp3')
      end

      it "truncates long text to save credits" do
        long_text = "A" * 300 + " more text"
        expected_text = long_text[0..250] + "..."
        
        expect(mock_client).to receive(:text_to_speech).with(
          'test_voice_id',
          expected_text,
          model_id: 'eleven_monolingual_v1'
        )
        
        service.generate_speech(long_text)
      end

      it "does not truncate short text" do
        short_text = "Short message"
        
        expect(mock_client).to receive(:text_to_speech).with(
          'test_voice_id',
          short_text,
          model_id: 'eleven_monolingual_v1'
        )
        
        service.generate_speech(short_text)
      end
    end

    context "with invalid inputs" do
      it "returns nil for blank text" do
        result = service.generate_speech("")
        expect(result).to be_nil
      end

      it "returns nil for nil text" do
        result = service.generate_speech(nil)
        expect(result).to be_nil
      end

      it "returns nil when API key is missing" do
        allow(ENV).to receive(:[]).with('ELEVENLABS_API_KEY').and_return(nil)
        service_with_no_key = described_class.new
        
        result = service_with_no_key.generate_speech(sample_text)
        expect(result).to be_nil
      end

      it "returns nil when API key is blank" do
        allow(ENV).to receive(:[]).with('ELEVENLABS_API_KEY').and_return('')
        service_with_blank_key = described_class.new
        
        result = service_with_blank_key.generate_speech(sample_text)
        expect(result).to be_nil
      end
    end

    context "when API call fails" do
      before do
        allow(mock_client).to receive(:text_to_speech).and_raise(StandardError, "API Error")
        allow(Rails.logger).to receive(:error)
      end

      it "logs error and returns nil" do
        expect(Rails.logger).to receive(:error).with(/ElevenLabs API error/)
        
        result = service.generate_speech(sample_text)
        expect(result).to be_nil
      end

      it "handles network errors gracefully" do
        allow(mock_client).to receive(:text_to_speech).and_raise(Timeout::Error)
        
        expect {
          service.generate_speech(sample_text)
        }.not_to raise_error
      end
    end
  end

  describe "#audio_file_path" do
    let(:text) { "Hello world" }
    let(:service_without_stub) { described_class.new }
    
    before do
      allow(::Elevenlabs::Client).to receive(:new).and_return(mock_client)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ELEVENLABS_API_KEY').and_return('test_api_key')
      allow(ENV).to receive(:[]).with('ELEVENLABS_DEFAULT_VOICE_ID').and_return('test_voice_id')
    end
    
    it "generates consistent file path based on text hash" do
      expected_hash = Digest::MD5.hexdigest(text.strip.downcase)[0..15]
      expected_path = Rails.root.join('public', 'audios', 'generated', "#{expected_hash}.mp3")
      
      path = service_without_stub.send(:audio_file_path, text)
      expect(path).to eq(expected_path)
    end

    it "returns same path for same text" do
      path1 = service_without_stub.send(:audio_file_path, text)
      path2 = service_without_stub.send(:audio_file_path, text)
      expect(path1).to eq(path2)
    end

    it "returns different paths for different text" do
      path1 = service_without_stub.send(:audio_file_path, "Hello")
      path2 = service_without_stub.send(:audio_file_path, "World")
      expect(path1).not_to eq(path2)
    end
  end

  describe "#save_audio_file" do
    let(:text) { "Test text" }
    let(:audio_data) { "binary_audio_data" }
    let(:file_path) { Rails.root.join('public', 'audios', 'generated', 'test_audio.mp3') }
    let(:mock_file) { double('File') }
    
    before do
      allow(service).to receive(:audio_file_path).and_return(file_path)
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:open).and_yield(mock_file)
      allow(mock_file).to receive(:write)
    end

    it "creates directory structure" do
      # Don't stub the save_audio_file method for this test
      allow(service).to receive(:save_audio_file).and_call_original
      expect(FileUtils).to receive(:mkdir_p).with(File.dirname(file_path))
      service.send(:save_audio_file, text, audio_data)
    end

    it "writes audio data to file" do
      # Don't stub the save_audio_file method for this test
      allow(service).to receive(:save_audio_file).and_call_original
      expect(File).to receive(:open).with(file_path, 'wb')
      expect(mock_file).to receive(:write).with(audio_data)
      service.send(:save_audio_file, text, audio_data)
    end

    it "handles file write errors gracefully" do
      allow(service).to receive(:save_audio_file).and_call_original
      allow(File).to receive(:open).and_raise(Errno::ENOENT)
      
      expect {
        service.send(:save_audio_file, text, audio_data)
      }.to raise_error(Errno::ENOENT)
    end
  end

  describe "default voice handling" do
    context "when default voice ID is not configured" do
      let(:service_with_no_default) { described_class.new }
      
      before do
        allow(::Elevenlabs::Client).to receive(:new).and_return(mock_client)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('ELEVENLABS_API_KEY').and_return('test_api_key')
        allow(ENV).to receive(:[]).with('ELEVENLABS_DEFAULT_VOICE_ID').and_return(nil)
        allow(mock_client).to receive(:text_to_speech).and_return(mock_response)
        allow(service_with_no_default).to receive(:save_audio_file)
        allow(service_with_no_default).to receive(:audio_file_path).and_return('/path/to/audio.mp3')
      end

      it "uses fallback voice ID" do
        expect(mock_client).to receive(:text_to_speech).with(
          'pNInz6obpgDQGcFmaJgB', # Adam voice fallback
          sample_text,
          model_id: 'eleven_monolingual_v1'
        )
        
        service_with_no_default.generate_speech(sample_text)
      end
    end
  end
end
