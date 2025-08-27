# AI Voice TLDR Workflow Guide

## Overview

This guide walks you through creating AI-generated audio TLDRs for your case studies using voice cloning and AI summarization.

## Step 1: Voice Cloning Setup

### Tools Needed:

- **ElevenLabs** (recommended) - https://elevenlabs.io
- **Alternative**: Play.ht, Descript

### Voice Sample Requirements:

- **Duration**: 3-5 minutes of clear speech
- **Content**: Natural conversation, not reading
- **Quality**: Clear audio, minimal background noise
- **Topics**: Speak about design, work, or any topic naturally

### Recording Tips:

- Use your phone's voice memo app
- Speak naturally as if explaining to a colleague
- Avoid reading from scripts
- Include natural pauses and emphasis

## Step 2: AI Summarization Prompt

### Use this prompt with Claude/GPT-4:

```
You are an expert at summarizing case studies into engaging, conversational audio scripts.

Please create a 2-minute audio script (approximately 200-250 words) based on this case study about Dropbox's activation strategy.

Requirements:
- Write in first person ("I", "we") as if I'm speaking directly to the listener
- Use conversational, engaging language
- Include the key problem, solution approach, and results
- End with 2-3 key learnings
- Keep it under 250 words for a 2-minute read
- Make it sound natural when spoken aloud

Case Study: [Paste your case study content here]

Please provide just the script, ready for voice generation.
```

## Step 3: Generate Audio

### ElevenLabs Workflow:

1. **Upload Script**: Paste the AI-generated script
2. **Select Voice**: Choose your cloned voice
3. **Adjust Settings**:
   - Stability: 0.5-0.7 (for natural variation)
   - Similarity: 0.7-0.8 (to match your voice)
4. **Generate**: Create the audio file
5. **Download**: Save as MP3

### File Naming Convention:

- `dropbox-activation-tldr.mp3`
- `dropbox-collaboration-tldr.mp3`
- `dropbox-flow-tldr.mp3`

## Step 4: Upload and Test

### File Placement:

- Upload MP3 files to `app/assets/audio/`
- Ensure file names match the ERB templates

### Testing:

- Refresh your case study page
- Test audio playback
- Verify transcript display
- Check mobile responsiveness

## Step 5: Iterate and Improve

### Common Adjustments:

- **Too fast/slow**: Regenerate with different voice settings
- **Unnatural emphasis**: Edit the script for better flow
- **Length issues**: Adjust script word count

### Quality Checklist:

- ✅ Audio is clear and natural
- ✅ Script flows conversationally
- ✅ Key points are emphasized
- ✅ Length is 1.5-2.5 minutes
- ✅ Transcript matches audio

## Example Script (Dropbox Activation)

Here's what a good script should look like:

```
"In 2021, Dropbox faced a critical challenge: customers weren't discovering the full value of our platform beyond basic file sharing. We identified three key problems: limited value discovery, trust erosion from frequent upsells, and overly complex foundational features.

Our solution involved establishing design rituals, improving data-driven decision making, and using a Design Sprint to validate our approach. We discovered that relevant communication dramatically improved feature discovery, leading to 12 experiments and ultimately a $50M+ increase in annual recurring revenue.

Key learnings: one-size-fits-all doesn't scale, goals drive outcomes more than principles, and time constraints are your friends. The project validated a new activation direction using data models for relevant recommendations."
```

## Troubleshooting

### Audio Won't Play:

- Check file path in ERB template
- Verify MP3 file is in correct directory
- Test with browser developer tools

### Voice Sounds Unnatural:

- Regenerate with different stability/similarity settings
- Record a new voice sample with more natural speech
- Try different voice models

### Script Too Long/Short:

- Adjust word count in AI prompt
- Use word count tools to verify length
- Aim for 200-250 words for 2 minutes

## Next Steps

1. **Record your voice sample** (3-5 minutes)
2. **Set up ElevenLabs account** and clone your voice
3. **Use the AI prompt** to generate your first script
4. **Generate audio** with your cloned voice
5. **Upload and test** on your case study page

## Resources

- **ElevenLabs Documentation**: https://docs.elevenlabs.io
- **Voice Cloning Best Practices**: https://elevenlabs.io/blog/voice-cloning-guide
- **Audio Format Requirements**: MP3, 44.1kHz, 128kbps minimum
