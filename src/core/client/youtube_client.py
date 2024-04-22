"""
Module for interacting with the YouTube API.
"""

import os
import textwrap
import logging

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

    def get_video_id(self, video_name=None):
        """
        Get the ID of the latest video in the channel.
        """
        # Call the search.list method to retrieve videos for the channel
        search_response = (
            self.youtube_client.search()
            .list(part="snippet", q=CHANNEL_NAME, type="channel")
            .execute()
        )

        # Extract the channel ID from the search results
        channel_id = search_response["items"][0]["id"]["channelId"]

        # Call the search.list method again to retrieve videos for the channel using its ID
        video = None
        if video_name is None:
            video = (
                self.youtube_client.search()
                .list(
                    part="snippet",
                    channelId=channel_id,
                    type="video",
                    order="date",
                )
                .execute()["items"][0]
            )
        else:  # Search for the last 50 videos (shorts included)
            video_response = (
                self.youtube_client.search()
                .list(
                    part="snippet",
                    channelId=channel_id,
                    type="video",
                    order="date",
                    maxResults=50,
                )
                .execute()
            )
            videos = video_response["items"]

            for _video in videos:
                logging.info(
                    "%s: %s", _video["id"]["videoId"], _video["snippet"]["title"]
                )
                if _video["snippet"]["title"] == video_name:
                    video = _video
                    break

        if video is None:
            raise Exception(f"Video, {video_name}, not found")

        return video["id"]["videoId"], video["snippet"]["title"]

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
