""" 
Main handler for the Lambda function.
"""

import hashlib

from client.youtube_client import YouTubeClient
from client.openai_client import OpenAIClient
from client.git_client import GitClient
from client.email_client import EmailClient


def main(event, _):
    """
    This is the main entry point for the Lambda function.
    It takes in the event and context as arguments, and returns the response.
    """
    action_name = event["actionName"]

    if action_name == "getVideoId":
        video_name = event["videoName"]
        video_url = event["videoUrl"]
        response = action_get_video_id(video_url)
    if action_name == "sendConfirmationEmail":
        video_name = event["videoName"]
        execution_name = event["ExecutionContext"]["Execution"]["Name"]
        statemachine_name = event["ExecutionContext"]["StateMachine"]["Name"]
        task_token = event["ExecutionContext"]["Task"]["Token"]
        function_url = event["processorLambdaFunctionUrl"]

        response = action_send_video_confirmation_email(
            video_name, function_url, execution_name, statemachine_name, task_token
        )
    if action_name == "generateBlogPost":
        video_id = event["videoId"]
        video_name = event["videoName"]
        video_type = event["videoType"]
        response = action_generate_blog_post(video_id, video_name, video_type)
    if action_name == "commitBlogToGitHub":
        blog_post_contents = event["blogPostContents"]
        video_name = event["videoName"]
        response = action_commit_blog_to_github(video_name, blog_post_contents)
    if action_name == "sendEmail":
        commit_id = event["commitId"]
        branch_name = event["branchName"]
        video_name = event["videoName"]
        response = action_send_email(commit_id, branch_name, video_name)

    return response


def action_get_video_id(video_name):
    """
    This function takes in a video name and returns the video ID and video name.
    """
    youtube_client = YouTubeClient()
    video_id, video_name = youtube_client.get_video_id(video_name)
    return {"videoId": video_id, "videoName": video_name}


def action_generate_blog_post(video_id, video_name, video_type):
    """
    This function takes in a video ID and returns the blog post contents.
    """
    transcript = YouTubeClient().get_video_transcript(video_id)
    markdown_blog = OpenAIClient().ask(transcript, video_name, video_type)
    return {"blogPostContents": markdown_blog}


def action_commit_blog_to_github(video_title, blog_post_contents):
    """
    This function takes in a video title and blog post contents
    and returns the commit ID and branch name.
    """
    git_client = GitClient()

    branch_name = hashlib.sha256(video_title.encode("utf-8")).hexdigest()
    repo = git_client.clone(branch_name)

    commit_info = git_client.commit(video_title, blog_post_contents, repo)
    git_client.push(repo)

    return {"commitId": commit_info.hexsha, "branchName": branch_name}


def action_send_video_confirmation_email(
    video_name, function_url, execution_name, statemachine_name, task_token
):
    """
    This function takes in a video name, function URL, execution name,
    state machine name, and task token and sends a
    video confirmation email. It returns the message ID.
    """
    email_client = EmailClient()
    response = email_client.send_video_confirmation_email(
        video_name, function_url, execution_name, statemachine_name, task_token
    )
    return {"messageId": response["MessageId"]}


def action_send_email(commit_id, branch_name, video_name):
    """
    This function takes in a commit ID, branch name, and video name and sends an email.
    """
    email_client = EmailClient()
    response = email_client.send_email(commit_id, branch_name, video_name)
    return {"messageId": response["MessageId"]}
