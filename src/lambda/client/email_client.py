import boto3
import os

TOPIC_ARN = os.environ.get("TOPIC_ARN")
REPOSITORY_URL = os.environ.get("REPOSITORY_URL")


class EmailClient:

    def __init__(self) -> None:
        self.sns_client = boto3.client("sns")

    def send_email(self, commit_id, branch_name, video_name):
        # Create Email Message
        subject = f"Blog Post Published for Video: {video_name}"
        repository_url = REPOSITORY_URL + "/tree/" + branch_name
        html_message = f"""
        <html>
        <body>
            <p>Your draft blog post for the following video, {video_name}, has been published to the dsb-digest! The information needed to find the post are highlighted below:</p>
            <p><strong>Repository URL:</strong> {repository_url}</p>
            <p><strong>Branch Name:</strong> {branch_name}</p>
            <p><strong>Commit ID:</strong> {commit_id}</p>
            <p><strong>:</strong> {commit_id}</p>
            <p>Happy writing! 🚀</p>
            <p>Sincerely,<br>DSB Blogging Assistant</p>
        </body>
        </html>
        """

        response = self.sns_client.publish(
            TopicArn=TOPIC_ARN, SubjectName=subject, Message=html_message
        )
        return response
