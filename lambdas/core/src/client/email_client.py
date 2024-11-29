"""
Email client module for sending emails to the user when a blog post is published.
"""

import os
import logging
import urllib.parse
import boto3

TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
REPOSITORY_URL = os.environ.get("REPOSITORY_URL")

logging.getLogger().setLevel(logging.INFO)


class EmailClient:  # pylint: disable=too-few-public-methods, line-too-long, too-many-positional-arguments
    """
    This class is responsible for sending emails to the user when a blog post is published.
    """

    def __init__(self) -> None:
        self.sns_client = boto3.client("sns")

    def send_email(self, commit_id, branch_name, video_name):
        """
        This function sends an email to the user when a blog post is published.
        """
        # Create Email Message
        subject = "New Blog Post Published for Video!"
        repository_url = REPOSITORY_URL + "/tree/" + branch_name
        html_message = (
            f"Your draft blog post for the following video, {video_name}, has been published to the dsb-digest!\n"
            "The information needed to find the post are highlighted below:\n\n"
            f"Repository URL: {repository_url}\n"
            f"Branch Name: {branch_name}\n"
            f"Commit ID: {commit_id}\n\n"
            "Happy writing! 🚀\n"
            "Sincerely,\nDSB Blogging Assistant\n"
        )

        response = self.sns_client.publish(
            TopicArn=TOPIC_ARN, Subject=subject, Message=html_message
        )
        return response

    def send_video_confirmation_email(
        self, video_name, function_url, execution_name, statemachine_name, task_token
    ):  # pylint: disable=too-many-arguments
        """
        This function is called when the lambda is triggered. It will send an email to the user
        to confirm if the video is technical or non-technical.
        """
        # Constructing approval and rejection endpoints
        confirm_technical_endpoint = f"{function_url}?action=yes&ex={execution_name}&sm={statemachine_name}&taskToken={urllib.parse.quote(task_token)}"
        confirm_nontechnical_endpoint = f"{function_url}?action=no&ex={execution_name}&sm={statemachine_name}&taskToken={urllib.parse.quote(task_token)}"

        # Construct the email message
        subject = "DSB Blogging Assistant: Video Type Confirmation Email"
        email_message = (
            "Hello Damien! \n\n"
            f"This email is confirming that video, {video_name}, is either technical or non-technical. "
            "Please click 'Yes' to confirm that the video is technical or 'No' for non-technical. \n\n"
            f"Yes: {confirm_technical_endpoint} \n\n"
            f"No: {confirm_nontechnical_endpoint} \n\n"
            "Happy writing! 🚀\n"
            "Sincerely,\nDSB Blogging Assistant\n"
        )

        response = self.sns_client.publish(
            TopicArn=TOPIC_ARN, Subject=subject, Message=email_message
        )

        return response
