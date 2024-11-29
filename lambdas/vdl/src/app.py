"""
Default application for YouTube event handling.
This application accepts requests from YT's pubsubhubbub.
"""

import os
import json
from xml.parsers.expat import ExpatError

import boto3
import xmltodict

from flask import Flask, request

STEP_FUNCTION_ARN = os.environ["STEP_FUNCTION_ARN"]

app = Flask(__name__)


@app.route("/test", methods=["GET"])
def test():
    """
    This function is used to test the application to ensure
    it is working properly, and available.
    """
    return "IT'S ALIVE!!!", 200


@app.route("/feed", methods=["GET", "POST"])
def feed():
    """
    This function is used to handle incoming YT events.
    Accept and parse requests from YT's pubsubhubbub.
    https://developers.google.com/youtube/v3/guides/push_notifications
    """

    challenge = request.args.get("hub.challenge")
    if challenge:
        # YT will send a challenge from time to time to confirm the server is alive.
        return challenge

    try:
        # Parse the XML from the POST request into a dict.
        xml_dict = xmltodict.parse(request.data)

        # Parse out the video URL & the title
        video_url = xml_dict["feed"]["entry"]["link"]["@href"]
        video_title = xml_dict["feed"]["entry"]["title"]

        # Trigger Step Function by passing in the video title and URL
        sfn_input = {
            "videoName": video_title,
            "videoUrl": video_url,
        }

        sfn_client = boto3.client("stepfunctions")
        response = sfn_client.start_execution(
            stateMachineArn=STEP_FUNCTION_ARN,
            input=json.dumps(sfn_input),
        )

    except (ExpatError, LookupError):
        # request.data contains malformed XML or no XML at all, return FORBIDDEN.
        return "", 403

    # Everything is good, return SFN Execution Response & HTTP 200.
    return response, 200


if __name__ == "__main__":
    app.run()
