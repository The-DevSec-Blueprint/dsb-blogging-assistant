# Python 3.12 AWS ECR Image
FROM public.ecr.aws/lambda/python:3.12

# Installs Git and Updates the base image
RUN dnf install -y git

# Configuring workspace and installing python dependencies
WORKDIR /var/task
COPY ./src .
COPY requirements.txt .
RUN pip install -r requirements.txt

CMD ["handler.main"]
