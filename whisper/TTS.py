import openai
import sys
from pathlib import Path

def main():
    """
    Simple script to convert text to speech using OpenAI's TTS endpoint.
    Usage:
        python TTS.py "Your text goes here"
    """

    # 1. Set your OpenAI API key
    openai.api_key = ""

    # 2. Parse text input
    if len(sys.argv) > 1:
        text_input = " ".join(sys.argv[1:])
    else:
        text_input = "Welcome to our demonstration of advanced text-to-speech technology. In this brief sample, you will experience natural, expressive speech that captures both clarity and emotion. Enjoy this immersive example that brings written text to life with remarkable human-like quality."

    # 3. Choose model & voice (from the doc: tts-1, tts-1-hd, voices like alloy, ash, etc.)
    model = "tts-1"       # standard TTS model
    voice = "alloy"       # one of the built-in voices

    # 4. Output file path
    out_file_path = Path("speech2.mp3")

    try:
        # 5. Call the TTS endpoint
        response = openai.audio.speech.create(
            model=model,
            voice=voice,
            input=text_input,
        )
        # 6. Save the resulting audio to an MP3
        response.stream_to_file(out_file_path)
        print(f"Audio saved to: {out_file_path}")
        print("Remember: You must disclose that this voice is AI-generated, per usage policies.")
    except Exception as e:
        print(f"Error generating TTS: {e}")

if __name__ == "__main__":
    main()
