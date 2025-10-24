# Ollama Migration Guide

This document outlines the migration from OpenAI/ElevenLabs to Ollama for local LLM inference.

## Overview

The application has been migrated from external AI services to Ollama for:

- Chat completions (replacing OpenAI GPT-4o-mini)
- Text embeddings (replacing OpenAI text-embedding-3-small)
- Text-to-speech (ElevenLabs integration removed for now)

## Setup Instructions

### 1. Install Ollama

```bash
# macOS
brew install ollama

# Or download from https://ollama.ai
```

### 2. Start Ollama Service

```bash
ollama serve
```

### 3. Download Required Models

```bash
# For chat completions and embeddings
ollama pull llama3.2

# Alternative models you can try:
# ollama pull llama3.1
# ollama pull mistral
# ollama pull codellama
```

### 4. Environment Configuration

Add these environment variables to your `.env` file:

```bash
# Ollama Configuration
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3.2
OLLAMA_TIMEOUT=30
```

### 5. Test the Integration

```bash
# Test basic Ollama connectivity
rails ollama:test

# Test conversation service
rails ollama:test_conversation
```

## Changes Made

### New Services

- `app/services/ollama_service.rb` - Core Ollama API client
- `app/services/ollama_conversation_service.rb` - Chat completion service
- `app/services/ollama_embedding_service.rb` - Embedding generation service

### Updated Components

- `app/controllers/jason_ai_controller.rb` - Now uses OllamaConversationService
- `app/models/knowledge_item.rb` - Uses OllamaEmbeddingService
- `app/models/knowledge_chunk.rb` - Uses OllamaEmbeddingService
- `app/models/additional_knowledge.rb` - Uses OllamaEmbeddingService

### Configuration

- `Gemfile` - Commented out ruby-openai and elevenlabs gems
- `.sample.env` - Added Ollama configuration variables

## Model Recommendations

### For Chat Completions

- **llama3.2** (recommended) - Good balance of performance and quality
- **llama3.1** - Slightly older but very stable
- **mistral** - Fast and efficient for simple tasks

### For Embeddings

- **llama3.2** - Same model for consistency
- **nomic-embed-text** - Specialized embedding model (if available)

## Performance Considerations

### Hardware Requirements

- **Minimum**: 8GB RAM for 7B models
- **Recommended**: 16GB+ RAM for better performance
- **GPU**: Optional but significantly faster with CUDA support

### Model Size vs Performance

- **7B models**: Good balance, requires ~8GB RAM
- **13B models**: Better quality, requires ~16GB RAM
- **70B models**: Best quality, requires 40GB+ RAM

## Troubleshooting

### Common Issues

1. **"Connection refused" errors**

   - Ensure Ollama is running: `ollama serve`
   - Check OLLAMA_BASE_URL is correct

2. **"Model not found" errors**

   - Pull the required model: `ollama pull llama3.2`
   - Check OLLAMA_MODEL matches installed model

3. **Slow responses**

   - Consider using a smaller model
   - Ensure adequate RAM is available
   - Check if GPU acceleration is working

4. **Embedding generation fails**
   - Some models don't support embeddings
   - Try a different model or use a specialized embedding model

### Testing Commands

```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Test model directly
ollama run llama3.2 "Hello, how are you?"

# Check available models
ollama list
```

## Rollback Plan

If you need to rollback to OpenAI:

1. Uncomment the gems in `Gemfile`:

   ```ruby
   gem "ruby-openai"
   gem "elevenlabs"
   ```

2. Update `jason_ai_controller.rb`:

   ```ruby
   @conversation_service = ConversationService.new
   ```

3. Update models to use `EmbeddingService.new`

4. Set environment variables:
   ```bash
   OPENAI_API_KEY=your_key
   ELEVENLABS_API_KEY=your_key
   ```

## Benefits of Ollama Migration

1. **Cost Savings** - No API usage fees
2. **Privacy** - All processing happens locally
3. **Reliability** - No external service dependencies
4. **Customization** - Use any compatible model
5. **Offline Capability** - Works without internet

## Next Steps

1. Test thoroughly in development
2. Monitor performance and adjust model size
3. Consider specialized models for different tasks
4. Implement model switching based on use case
5. Add monitoring for Ollama service health
