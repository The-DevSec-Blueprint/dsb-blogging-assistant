import logging
from openai import OpenAI

from client.ssm_client import SsmClient

logging.getLogger().setLevel(logging.INFO)

BASE_QUESTION = """Hello! Could you create a 2000-2500 word detailed blog post 
in markdown with placeholders for pictures and diagrams 
in first person that are based on the transcript below:\n """

MD_METADATA = """---
title: TBD
subtitle: TBD
slug: TBD
tags: TBD
cover: TBD
domain: damienjburks.hashnode.dev
saveAsDraft: true
---
"""


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
            model="gpt-4-0125-preview",
        )

        answer = MD_METADATA + "\n\n" + chat_completion.choices[0].message.content

        logging.info("API call was successful! OpenAI response: %s", answer)
        return answer

    def _create_authenticated_client(self):
        auth_token = SsmClient().get_parameter(name="/credentials/openai/auth_token")
        return OpenAI(api_key=auth_token)
