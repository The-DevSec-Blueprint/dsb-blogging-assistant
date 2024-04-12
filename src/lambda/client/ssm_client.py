"""
Module for interacting with SSM Parameter Store.
"""

import boto3


class SsmClient:  # pylint: disable=too-few-public-methods
    """
    Class for interacting with SSM Parameter Store.
    """

    def __init__(self):
        self.client = boto3.client("ssm")

    def get_parameter(self, name):
        """
        Get parameter from SSM Parameter Store.
        """

        return self.client.get_parameter(Name=name, WithDecryption=True)["Parameter"][
            "Value"
        ]
