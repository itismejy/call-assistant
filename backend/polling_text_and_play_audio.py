import firebase_admin
from firebase_admin import credentials, storage
import time
import os
import openai
import sys
from pathlib import Path
from playsound import playsound

# Global counter for filenames
file_counter = 1
openai.api_key = ""

def get_next_filename():
    """
    Generate the next incremental filename in the format convo_{digit}.mp3.
    """
    global file_counter
    filename = f"convo_{file_counter}.mp3"
    file_counter += 1  # Increment the counter for the next file
    return filename

def record_audio(text_input, local_path):
    model = "tts-1"       # standard TTS model
    voice = "alloy"       # one of the built-in voices

    # 4. Output file path
    out_file_path = Path(local_path)

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


# Define your bucket and credentials
BUCKET = "call-assistant-27ff1.firebasestorage.app"
cred = credentials.Certificate("/Users/michaelzhang/Downloads/call-assistant-27ff1-89b88301fe3c.json")

# Initialize Firebase Admin SDK
firebase_admin.initialize_app(cred, {
    'storageBucket': BUCKET
})

# Create a storage client
bucket = storage.bucket()

# Define the path to list blobs
path = "text/"

# Keep track of last seen files
last_seen_files = set()

while True:
    # List all files in the specified path
    blobs = list(bucket.list_blobs(prefix=path))
    
    # Filter for new blobs
    new_blobs = [blob for blob in blobs if blob.name not in last_seen_files]
    
    # Process new blobs
    for blob in new_blobs:
        if blob.name.endswith('.txt'):
            print(f"New audio file detected: {blob.name}")
            
            # Define the local filename to save the downloaded text file
            local_filename = os.path.join(os.getcwd(), blob.name.split('/')[-1])  # Save in current directory
            
            # Download the new text file locally
            blob.download_to_filename(local_filename)
            print(f"Downloaded: {local_filename}")

            # Read the content of the downloaded text file
            with open(local_filename, 'r') as file:
                text_input = file.read().strip()  # Read and strip any extra whitespace
            
            # Get the next filename for audio output
            local_audio_path = get_next_filename()

            # Call record_audio with text input and local audio path
            record_audio(text_input=text_input, local_path=local_audio_path)

            # Play the audio file
            playsound(local_audio_path)
    
    # Update the set of last seen files
    last_seen_files = {blob.name for blob in blobs}
    
    print("Next round")
    
    # Wait before polling again
    time.sleep(5)  
    
    
