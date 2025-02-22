import openai
import sys

def main():
    """
    Simple script to transcribe audio to text using OpenAI's Whisper endpoint.
    Usage:
        python STT.py path/to/audio.mp3
    """

    # 1. Set your OpenAI API key
    openai.api_key = ""

    # 2. Parse audio file path
    if len(sys.argv) > 1:
        audio_file_path = sys.argv[1]
    else:
        print("Usage: python STT.py /Users/ShareefJasim/Projects/Callie/call-assistant/whisper/speech.mp3")
        return

    try:
        # 3. Open the audio file in binary mode
        with open(audio_file_path, "rb") as audio_file:
            # 4. Call the transcriptions endpoint (for STT in original language)
            transcription = openai.audio.transcriptions.create(
                model="whisper-1",
                file=audio_file,
                # Optional parameters:
                # response_format="text",  # or "json", "verbose_json"
                # temperature=0.0,
                # prompt="Hello, this is a sample prompt that can help with context..."
            )
        # 5. Print the transcribed text
        print("Transcribed Text:", transcription.text)
    except Exception as e:
        print(f"Error transcribing audio: {e}")

if __name__ == "__main__":
    main()
