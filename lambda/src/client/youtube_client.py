from googleapiclient.discovery import build
from youtube_transcript_api import YouTubeTranscriptApi
import textwrap

# YouTube API key
# TODO: Rotate this key to prevent abuse.
api_key = "AIzaSyDcYBTNiVmMEu6xWDRK5tTbxHx9FCf8_XI"  # Put into SSM Parameter Store or Secrets Manager

# The name of the channel
channel_name = "The DevSec Blueprint (DSB)"  # Store in Lambda ENV Variable

# Initialize the YouTube Data API client
youtube = build("youtube", "v3", developerKey=api_key)

# Call the search.list method to retrieve videos for the channel
search_response = (
    youtube.search().list(part="snippet", q=channel_name, type="channel").execute()
)

# Extract the channel ID from the search results
channel_id = search_response["items"][0]["id"]["channelId"]

# Call the search.list method again to retrieve videos for the channel using its ID
latest_video = (
    youtube.search()
    .list(
        part="snippet",
        channelId=channel_id,
        type="video",
        order="date",
    )
    .execute()["items"][0]
)

latest_video_id = latest_video["id"]["videoId"]

transcript = YouTubeTranscriptApi.get_transcript(
    video_id=latest_video_id, languages=["en"]
)


def format_transcript(transcript, max_line_width=80):
    formatted_transcript = ""
    wrapper = textwrap.TextWrapper(width=max_line_width)

    for entry in transcript:
        wrapped_text = wrapper.fill(text=entry["text"])
        formatted_transcript += wrapped_text + "\n"
    return formatted_transcript


formatted_transcript = format_transcript(transcript)
