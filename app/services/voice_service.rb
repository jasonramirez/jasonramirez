class VoiceService
  def initialize
    @client = ::Elevenlabs::Client.new(api_key: ENV['ELEVENLABS_API_KEY'])
  end

  def generate_speech(text, voice_id = nil)
    return nil if text.blank? || ENV['ELEVENLABS_API_KEY'].blank?

    begin
      # Use default voice if none specified
      voice_id ||= ENV['ELEVENLABS_DEFAULT_VOICE_ID'] || 'pNInz6obpgDQGcFmaJgB' # Adam voice
      
      # Limit text length to save ElevenLabs credits (approximately 50 words)
      short_text = if text.length > 250
        text[0..250] + "..."
      else
        text
      end
      
      response = @client.text_to_speech(
        voice_id,
        short_text,
        model_id: 'eleven_monolingual_v1'  # More cost-effective model
      )
      
      # Save the audio file
      save_audio_file(text, response)
      
      # Return the audio file path
      audio_file_path(text)
      
    rescue => e
      Rails.logger.error "ElevenLabs API error: #{e.message}"
      nil
    end
  end

  def list_voices
    return [] if ENV['ELEVENLABS_API_KEY'].blank?

    begin
      result = @client.list_voices
      
      # Handle the response properly - it should be a hash with a 'voices' key
      if result.is_a?(Hash) && result['voices']
        result['voices']
      else
        Rails.logger.error "Unexpected ElevenLabs response format: #{result.class}"
        []
      end
    rescue => e
      Rails.logger.error "ElevenLabs voices error: #{e.message}"
      []
    end
  end

  private

  def save_audio_file(text, audio_data)
    # Create a unique filename based on text content
    filename = generate_filename(text)
    filepath = audio_file_path(text)
    
    # Ensure directory exists
    FileUtils.mkdir_p(File.dirname(filepath))
    
    # Save the audio file
    File.open(filepath, 'wb') do |file|
      file.write(audio_data)
    end
  end

  def generate_filename(text)
    # Create a hash of the text for consistent filenames
    Digest::MD5.hexdigest(text.strip.downcase)[0..15]
  end

  def audio_file_path(text)
    filename = generate_filename(text)
    Rails.root.join('public', 'audios', 'generated', "#{filename}.mp3")
  end
end
