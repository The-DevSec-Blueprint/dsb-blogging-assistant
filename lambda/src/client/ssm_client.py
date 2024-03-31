import boto3


class SsmClient:

    def __init__(self, region_name):
        self.client = boto3.client("ssm", region_name=region_name)

    def get_parameter(self, name):
        return self.client.get_parameter(Name=name)["Parameter"]["Value"]
