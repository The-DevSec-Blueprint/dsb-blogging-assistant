"""
Module for interacting with the YouTube API.
"""

import os
import textwrap
import logging

from urllib.parse import urlparse, parse_qs
from isodate import parse_duration
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
        self.ssm_client = SsmClient()
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
            video_id = parse_qs(parsed_url.query).get("v", [None])[0]

            response = (
                self.youtube_client.videos()
                .list(part="contentDetails", id=video_id)
                .execute()
            )

            # Get the duration of the video and check if it's less than 60 seconds
            duration = response["items"][0]["contentDetails"]["duration"]
            duration_seconds = parse_duration(duration).total_seconds()
            if duration_seconds < 60:
                return video_id, True

            return video_id, False

        raise Exception("Invalid YouTube URL.")

    def get_video_transcript(self, latest_video_id, max_line_width=80):
        """
        Get the transcript of the latest video in the channel.
        """
        username = self.ssm_client.get_parameter("/credentials/smartproxy/username")
        password = self.ssm_client.get_parameter("/credentials/smartproxy/password")
        proxy = f"http://{username}:{password}@gate.smartproxy.com:10001"

        transcript = YouTubeTranscriptApi.get_transcript(
            video_id=latest_video_id,
            languages=["en"],
            proxies={"http": proxy, "https": proxy},
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
        api_key = self.ssm_client.get_parameter("/credentials/youtube/auth_token")
        return build("youtube", "v3", developerKey=api_key)
