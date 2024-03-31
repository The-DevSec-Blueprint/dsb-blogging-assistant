import logging
from openai import OpenAI

from client.ssm_client import SsmClient

BASE_QUESTION = """Hello! Could you create a summarized 1500-word blog 
post in markdown with pictures/diagrams in first person 
that are based on the following transcript: """


class OpenAIClient:
    def __init__(self) -> None:
        self.openai_client = self._create_authenticated_client()

    def ask(self, transcript):
        question = BASE_QUESTION + transcript + "\n\n"

        chat_completion = self.openai_client.chat.completions.create(
            messages=[
                {
                    "role": "user",
                    "content": question,
                }
            ],
            model="gpt-3.5-turbo",
        )

        answer = chat_completion.choices[0].message.content

        logging.info("Call to ChatGPT was successful: %s", answer)
        return answer

    def _create_authenticated_client(self):
        auth_token = SsmClient().get_parameter(name="/credentials/openai/auth_token")
        return OpenAI(api_key=auth_token)
