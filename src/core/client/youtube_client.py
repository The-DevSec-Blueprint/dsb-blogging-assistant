"""
Module for interacting with the YouTube API.
"""

import os
import textwrap
import logging

from urllib.parse import urlparse, parse_qs
from googleapiclient.discovery import build
from youtube_transcript_api import YouTubeTranscriptApi
from client.ssm_client import SsmClient

logging.getLogger().setLevel(logging.INFO)

CHANNEL_NAME = os.environ.get("YOUTUBE_CHANNEL_NAME")


class YouTubeClient:  # pylint: disable=no-member, broad-exception-raised
    """
    Class for interacting with the YouTube API.
    """

    def __init__(self):
        self.youtube_client = self._create_authenticated_client()

    def get_video_id(self, video_url):
        """
        Get the ID of the latest video in the channel.
        """
        # Parse the URL
        parsed_url = urlparse(video_url)

        # Check if it's a YouTube URL
        if "youtube.com" in parsed_url.netloc or "youtu.be" in parsed_url.netloc:
            # Extract query parameters from the URL
            query_params = parse_qs(parsed_url.query)

            # The video ID is typically under the 'v' parameter for YouTube URLs
            return query_params.get("v", [None])[0]

        return None

    def get_video_transcript(self, latest_video_id, max_line_width=80):
        """
        Get the transcript of the latest video in the channel.
        """
        transcript = YouTubeTranscriptApi.get_transcript(
            video_id=latest_video_id, languages=["en"]
        )

        formatted_transcript = ""
        wrapper = textwrap.TextWrapper(width=max_line_width)

        for entry in transcript:
            wrapped_text = wrapper.fill(text=entry["text"])
            formatted_transcript += wrapped_text + "\n"
        return formatted_transcript

    def _create_authenticated_client(self):
        """
        Create an authenticated YouTube API client.
        """

        ssm_client = SsmClient()
        api_key = ssm_client.get_parameter("/credentials/youtube/auth_token")
        return build("youtube", "v3", developerKey=api_key)
