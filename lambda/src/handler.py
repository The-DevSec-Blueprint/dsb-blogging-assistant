from client.youtube_client import YouTubeClient
from client.openai_client import OpenAIClient

def main(event, _):
    action_name = event["actionName"]
    video_name = event["videoName"]

    if action_name == "getVideoId":
        response = action_get_video_id(video_name)
    if action_name == "generateBlogPost":
        video_id = event["videoId"]
        response = action_generate_blog_post(video_id)

    return response


def action_get_video_id(video_name):
    youtube_client = YouTubeClient()
    video_id, video_name = youtube_client.get_video_id(video_name)
    return {
        "videoId": video_id,
        "videoName": video_name
    }

def action_generate_blog_post(video_id):
    transcript = YouTubeClient().get_video_transcript(video_id)
    markdown_blog = OpenAIClient.ask(transcript)
    return {
        "blogPostContents": markdown_blog
    }
