import logging
from src.public_modules.openai import OpenAI

BASE_QUESTION = """Hello! Could you create a 1500-word blog 
post in markdown with pictures/diagrams in first person 
that are based on the information below: """


class OpenAIClient:
    def __init__(self, api_key) -> None:
        self.openai_client = OpenAI(api_key=api_key)

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
