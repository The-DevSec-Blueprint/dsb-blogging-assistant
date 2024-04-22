"""
Main handler
"""

from os import environ
import logging
import requests

HUB_ENDPOINT = "https://pubsubhubbub.appspot.com/subscribe"
TOPIC_URL = environ.get("TOPIC_URL")
CALLBACK_URL = environ.get("CALLBACK_URL")

logging.getLogger().setLevel(logging.INFO)


def main(event, _):
    # pylint: disable=broad-exception-raised
    """
    Main function for subscribing to PubSubHubBub
    """

    logging.info("Subscribing to %s", TOPIC_URL)
    logging.info("Callback URL: %s", CALLBACK_URL)
    logging.info("Endpoint: %s", HUB_ENDPOINT)
    logging.info("Event Trigger: %s", event)

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
        logging.info("Subscription request accepted!")
        return "Subscription request accepted!", response.status_code

    logging.error("Subscription request failed: %s", response)
    raise Exception(f"Subscription request failed: {response}")
