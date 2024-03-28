from googleapiclient.discovery import build
import requests
import re

# YouTube API key
api_key = 'AIzaSyDcYBTNiVmMEu6xWDRK5tTbxHx9FCf8_XI' # Put into SSM Parameter Store or Secrets Manager

# The name of the channel
channel_name = 'The DevSec Blueprint (DSB)' # Store in Lambda ENV Variable

# Initialize the YouTube Data API client
youtube = build('youtube', 'v3', developerKey=api_key)

# Call the search.list method to retrieve videos for the channel
search_response = youtube.search().list(
    part='snippet',
    q=channel_name,
    type='channel'
).execute()

# Extract the channel ID from the search results
channel_id = search_response['items'][0]['id']['channelId']

# Call the search.list method again to retrieve videos for the channel using its ID
latest_video = youtube.search().list(
    part='snippet',
    channelId=channel_id,
    type='video',
    order='date',
    videoDuration='long',
).execute()["items"][0]

latest_video_id = latest_video['id']['videoId']

def get_video_transcript(video_id):
    # Retrieve captions for the video
    captions_response = youtube.captions().list(
        part='snippet',
        videoId=video_id
    ).execute()

    # Find the caption track corresponding to the transcript
    transcript_caption_track = None
    for caption in captions_response['items']:
        if caption['snippet']['trackKind'] == 'standard' and caption['snippet']['language'] == 'en':
            transcript_caption_track = caption
            break

    if transcript_caption_track:
        # Download the caption track
        caption_url = transcript_caption_track['snippet']['url']
        caption_data = requests.get(caption_url).text

        # Parse the caption track to extract the transcript
        transcript = ''
        for line in caption_data.splitlines():
            if re.match(r'^\d+:\d+:\d+', line):
                continue  # Skip timestamp lines
            transcript += line.strip() + ' '

        return transcript
    else:
        return "Transcript not available for this video."
    
transcript = get_video_transcript(latest_video_id)
print(transcript)