import hashlib

from client.youtube_client import YouTubeClient
from client.openai_client import OpenAIClient
from client.git_client import GitClient


def main(event, _):
    action_name = event["actionName"]

    if action_name == "getVideoId":
        video_name = event["videoName"]
        response = action_get_video_id(video_name)
    if action_name == "generateBlogPost":
        video_id = event["videoId"]
        response = action_generate_blog_post(video_id)
    if action_name == "commitBlogToGitHub":
        blog_post_contents = event["blogPostContents"]
        video_name = event["videoName"]
        response = action_commit_blog_to_github(video_name, blog_post_contents)
    if action_name == "sendEmail":
        commitId = event["commitId"]
        branchName = event["branchName"]
        response = action_send_email(commitId, branchName)

    return response


def action_get_video_id(video_name):
    youtube_client = YouTubeClient()
    video_id, video_name = youtube_client.get_video_id(video_name)
    return {"videoId": video_id, "videoName": video_name}


def action_generate_blog_post(video_id):
    transcript = YouTubeClient().get_video_transcript(video_id)
    markdown_blog = OpenAIClient().ask(transcript)
    return {"blogPostContents": markdown_blog}


def action_commit_blog_to_github(video_title, blog_post_contents):
    git_client = GitClient()

    branch_name = hashlib.sha256(video_title.encode("utf-8")).hexdigest()
    repo = git_client.clone(branch_name)

    commit_info = git_client.commit(video_title, blog_post_contents, repo)
    git_client.push(repo)

    return {"commitId": commit_info.hexsha, "branchName": branch_name}


def action_send_email(commitId, branchName):
    pass
