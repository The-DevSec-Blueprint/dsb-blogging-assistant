"""
Module for  interacting with OpenAI APIs.
"""

import logging
from openai import OpenAI

from client.ssm_client import SsmClient

logging.getLogger().setLevel(logging.INFO)

NONTECHNICAL_QUESTION = """Hello! Could you create a 2000-2500 word detailed blog post\n
in markdown with placeholders for pictures and diagrams\n
in first person that are based on the transcript below:\n"""

TECHNICAL_QUESTION = """Hello! Can you write me a comprehensive 5000-word technical\n
blog post with placeholders for pictures and\n
diagrams in markdown based on the title below:\n
{VIDEO_NAME}\n\n
Please use the transcript as a guide:\n
"""

MD_METADATA = """---
title: TBD
subtitle: TBD
slug: TBD
tags: TBD
cover: TBD
domain: damienjburks.hashnode.dev
saveAsDraft: true
enableToc: true
---
"""


class OpenAIClient:  # pylint: disable=too-few-public-methods
    """
    This class is responsible for interacting with the OpenAI API.
    """

    def __init__(self) -> None:
        self.openai_client = self._create_authenticated_client()

    def ask(self, transcript, video_name, video_type):
        """
        This function sends a question to the OpenAI API and returns the response.
        """

        if video_type == "technical":
            question = (
                TECHNICAL_QUESTION.format(VIDEO_NAME=video_name) + transcript + "\n\n"
            )
        else:
            question = NONTECHNICAL_QUESTION + transcript + "\n\n"

        chat_completion = self.openai_client.chat.completions.create(
            messages=[
                {
                    "role": "user",
                    "content": question,
                }
            ],
            model="gpt-4o",
        )

        answer = MD_METADATA + "\n\n" + chat_completion.choices[0].message.content

        logging.info("API call was successful! OpenAI response: %s", answer)
        return answer

    def _create_authenticated_client(self):
        """
        This function creates an authenticated OpenAI client.
        """

        auth_token = SsmClient().get_parameter(name="/credentials/openai/auth_token")
        return OpenAI(api_key=auth_token)
