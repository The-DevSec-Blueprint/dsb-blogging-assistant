from openai import OpenAI

CHATGPT_API_KEY = "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"

def ask_chatgpt(prompt):
    """
    """
    client = OpenAI(api_key=CHATGPT_API_KEY)

    chat_completion = client.chat.completions.create(
        messages=[
            {
                "role": "user",
                "content": prompt,
            }
        ],
        model="gpt-3.5-turbo",
    )
    print(chat_completion.choices[0].message.content)

if __name__ == "__main__":
    transcript = ""
    question = f"Hello! Could you create a 1500-word blog post in markdown with pictures/diagrams in first person that are based on the information below: {transcript}"
