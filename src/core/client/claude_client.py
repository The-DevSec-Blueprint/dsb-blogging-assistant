"""
Module for  interacting with OpenAI APIs.
"""

import json
import logging
import boto3

logging.getLogger().setLevel(logging.INFO)

NONTECHNICAL_QUESTION = """Hello! Could you create a 2000-2500 word detailed blog post\n
in markdown with placeholders for pictures and diagrams\n
in first person that are based on the transcript below?\n"""

TECHNICAL_QUESTION = """Hello! Can you write me a comprehensive 5000-word technical\n
blog post with placeholders for pictures and\n
diagrams in markdown based on the title '{VIDEO_NAME}'\n
Please use the transcript below as a guide.\n
"""

FM_DIRECTIONS = """Please include frontmatter metadata\n
into the markdown post or response with the following parameters:\n
title, slug, subtitles, tags, cover, domain set as damienjburks.hashnode.dev,\n
saveAsDraft set to true, and enableToc set to true.\n
"""


class ClaudeClient:  # pylint: disable=too-few-public-methods
    """
    This class is responsible for interacting with the OpenAI API.
    """

    def __init__(self) -> None:
        self.bedrock_client = boto3.client("bedrock-runtime", region_name="us-east-1")

    def ask(self, transcript, video_name, video_type):
        """
        This function sends a question to the OpenAI API and returns the response.
        """

        if video_type == "technical":
            prompt = (
                TECHNICAL_QUESTION.format(VIDEO_NAME=video_name)
                + FM_DIRECTIONS
                + transcript
            )
        else:
            prompt = NONTECHNICAL_QUESTION + FM_DIRECTIONS + transcript

        # Set the model ID, e.g., Claude 3 Haiku.
        model_id = "anthropic.claude-3-sonnet-20240229-v1:0:28k"

        # Format the request payload using the model's native structure.
        native_request = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 10000,  # Hopefully this'll be enough.
            "temperature": 0.5,
            "messages": [
                {
                    "role": "user",
                    "content": [{"type": "text", "text": prompt}],
                }
            ],
        }

        # Convert the native request to JSON, and invoke model.
        request = json.dumps(native_request)
        response = self.bedrock_client.invoke_model(modelId=model_id, body=request)

        # Decode the response body.
        model_response = json.loads(response["body"].read())

        # Extract and print the response text.
        return model_response["content"][0]["text"]
