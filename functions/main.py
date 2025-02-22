# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_admin import initialize_app
from llama_index.core.agent import ReActAgent
from llama_index.llms.gemini import Gemini



# initialize_app()
#
#
@https_fn.on_request()
async def on_request_example(req: https_fn.Request) -> https_fn.Response:
    llm = Gemini(
        model="models/gemini-1.5-flash",
        api_key="AIzaSyDBtRAejlTqKqNVBqUX8iyg3vTSY7IO_YA",
        # api_key="some key",  # uses GOOGLE_API_KEY env var by default
    )
    resp = await llm.complete("Write a poem about a magic backpack")
    print(resp)
    return https_fn.Response(resp)