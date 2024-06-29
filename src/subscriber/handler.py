"""
Main handler
"""

from os import environ
import logging
import requests
import boto3

HUB_ENDPOINT = "https://pubsubhubbub.appspot.com/subscribe"
TOPIC_URL = environ.get("TOPIC_URL")
CALLBACK_TASK_ARN = environ.get("CALLBACK_TASK_ARN")
CLUSTER_NAME = environ.get("CLUSTER_NAME")

# Logging Configuration
logging.getLogger().setLevel(logging.INFO)

# Clients
ecs_client = boto3.client("ecs")
ec2_client = boto3.client("ec2")


def main(event, _):
    # pylint: disable=broad-exception-raised
    """
    Main function for subscribing to PubSubHubBub
    """

    logging.info("Subscribing to %s", TOPIC_URL)
    logging.info("Callback Task ARN: %s", CALLBACK_TASK_ARN)
    logging.info("Endpoint: %s", HUB_ENDPOINT)
    logging.info("Event Trigger: %s", event)

    callback_url = _get_callback_url()

    params = {
        "hub.mode": "subscribe",
        "hub.topic": TOPIC_URL,
        "hub.callback": callback_url,
        "hub.verify": "async",  # Asynchronous verification method
        "hub.lease_seconds": "86400",  # Lease for 1 day
    }

    # Make a POST request to subscribe to the topic
    response = requests.post(HUB_ENDPOINT, data=params, timeout=5)

    # Check the response
    if response.status_code == 202:
        logging.info("Subscription request accepted!")
        return "Subscription request accepted!", response.status_code

    logging.error("Subscription request failed: %s", response)
    raise Exception(f"Subscription request failed: {response}")


def _get_callback_url():
    """
    This function retrieves the public IP address of the task running the callback.
    It uses the ECS and EC2 clients to get the network interface ID and then the public IP address.
    Returns:
        str: The callback URL with the public IP address
    """
    task_arn = ecs_client.list_tasks(
        cluster=CLUSTER_NAME,
    )[
        "taskArns"
    ][0]

    networking_details = ecs_client.describe_tasks(
        cluster=CLUSTER_NAME, tasks=[task_arn]
    )["tasks"][0]["attachments"][0]["details"]

    for details in networking_details:
        if details["name"] == "networkInterfaceId":
            logging.info("Network Interface ID: %s", details["value"])
            network_interface_id = details["value"]
            break

    public_ip = ec2_client.describe_network_interfaces(
        NetworkInterfaceIds=[network_interface_id]
    )["NetworkInterfaces"][0]["Association"]["PublicIp"]

    return f"http://{public_ip}/feed"
