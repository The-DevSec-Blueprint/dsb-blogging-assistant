"""
Email client module for sending emails to the user when a blog post is published.
"""

import boto3
import os

TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
REPOSITORY_URL = os.environ.get("REPOSITORY_URL")


class EmailClient:
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
        subject = f"Blog Post Published for Video: {video_name}"
        repository_url = REPOSITORY_URL + "/tree/" + branch_name
        html_message = f"""
Your draft blog post for the following video, {video_name}, has been published to the dsb-digest! The information needed to find the post are highlighted below:\n\n
Repository URL: {repository_url}\n
Branch Name: {branch_name}\n
Commit ID: {commit_id}\n\n
Happy writing! 🚀\n
Sincerely,\nDSB Blogging Assistant\n
        """

        response = self.sns_client.publish(
            TopicArn=TOPIC_ARN, Subject=subject, Message=html_message
        )
        return response
