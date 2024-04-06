# DSB Blogging Assistant

The name will come in the future. For now, we're going to go with this.

Terrafrom deployer setup with GitHub actions and all that: https://developer.hashicorp.com/terraform/tutorials/automation/github-actions

# Installing in Lambda DIR
pip install -r requirements.txt -t /path/to/deployment/package

# Event Driven PubSubHub
https://developers.google.com/youtube/v3/guides/push_notifications
https://github.com/BryanCuneo/yt-to-discord/tree/main?tab=readme-ov-file

# Subscribing to YouTube
In the 'Subscribe/Unsubscribe' mode, fill out the first four boxes:

- Callback URL - the URL you copied in step 3, followed by /feed. Ex: http://1829c24236ed.ngrok.io/feed
- Topic URL - https://www.youtube.com/xml/feeds/videos.xml?channel_id=CHANNEL_ID where CHANNEL_ID is the YouTube channel ID for the channel you'd like to subscribe to. in this case, it would be: UCOSYuY_e_r5GtVdlCVwY83Q
- Verify type - Asynchronous
- Mode - Subscribe Press the 'Do It!' button. Within a few minutes, you should see a GET request to /feed on your ngrok interface and a response code of 200.