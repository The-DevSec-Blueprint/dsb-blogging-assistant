# Dockerfile for Lambda Function - will upload to ECR
# and use this for executing code
FROM public.ecr.aws/lambda/python:3.11

WORKDIR /var/task
COPY ./lambda/src .
COPY requirements.txt .
RUN pip install -r requirements.txt

CMD ["handler.main"]
