import xmltodict
import yaml

from flask import Flask, request
from xml.parsers.expat import ExpatError


try:
    with open("./config.yaml") as f:
        config = yaml.load(f, Loader=yaml.FullLoader)
except FileNotFoundError:
    print("Unable to load config file: 'config.yaml'")
    print("Exiting...")
    exit(1)


app = Flask(__name__)


@app.route("/feed", methods=["GET", "POST"])
def feed():
    """Accept and parse requests from YT's pubsubhubbub.
    https://developers.google.com/youtube/v3/guides/push_notifications
    """

    challenge = request.args.get("hub.challenge")
    if challenge:
        # YT will send a challenge from time to time to confirm the server is alive.
        return challenge

    try:
        # Parse the XML from the POST request into a dict.
        xml_dict = xmltodict.parse(request.data)

        # Lazy verification - check if the POST request is from a channel ID that's been
        # set in config["channel_ids"].  Skip the check if that config option is empty.
        channel_id = xml_dict["feed"]["entry"]["yt:channelId"]
        if config["channel_ids"] != [] and channel_id not in config["channel_ids"]:
            return "", 403

        # Parse out the video URL.
        video_url = xml_dict["feed"]["entry"]["link"]["@href"]
        print("New video URL: {}".format(video_url))

    except (ExpatError, LookupError):
        # request.data contains malformed XML or no XML at all, return FORBIDDEN.
        return "", 403

    # Everything is good, return NO CONTENT.
    return "", 204


if __name__ == "__main__":
    app.run()