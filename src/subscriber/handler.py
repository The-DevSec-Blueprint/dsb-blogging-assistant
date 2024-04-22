"""
Main handler
"""

from os import environ
import requests

HUB_ENDPOINT = "https://pubsubhubbub.appspot.com/subscribe"
TOPIC_URL = environ.get("TOPIC_URL")
CALLBACK_URL = environ.get("CALLBACK_URL")


def main(_):
    # pylint: disable=broad-exception-raised
    """
    Main function for subscribing to PubSubHubBub
    """

    params = {
        "hub.mode": "subscribe",
        "hub.topic": TOPIC_URL,
        "hub.callback": CALLBACK_URL,
        "hub.verify": "async",  # Asynchronous verification method
    }

    # Make a POST request to subscribe to the topic
    response = requests.post(HUB_ENDPOINT, data=params, timeout=5)

    # Check the response
    if response.status_code == 202:
        return "Subscription request accepted!", response.status_code

    raise Exception("Subscription request failed!")
