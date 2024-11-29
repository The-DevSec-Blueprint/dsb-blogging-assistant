# DSB Blogging Assistant

![Build Status](https://github.com/The-DevSec-Blueprint/dsb-blogging-assistant/actions/workflows/main.yml/badge.svg?logo=github)
![License](https://img.shields.io/github/license/The-DevSec-Blueprint/dsb-blogging-assistant?logo=license)
![Terraform Registry](https://img.shields.io/badge/Terraform-Registry-purple?logo=terraform)
![Python Requirements](https://img.shields.io/badge/python-3.12-blue?logo=python)
![GitHub Issues](https://img.shields.io/github/issues/The-DevSec-Blueprint/dsb-blogging-assistant?logo=github)
![GitHub Forks](https://img.shields.io/github/forks/The-DevSec-Blueprint/dsb-blogging-assistant?logo=github)
![GitHub Stars](https://img.shields.io/github/stars/The-DevSec-Blueprint/dsb-blogging-assistant?logo=github)
![GitHub Last Commit](https://img.shields.io/github/last-commit/The-DevSec-Blueprint/dsb-blogging-assistant?logo=github)

<p align="center"><img src="./docs/images/logo.svg" /></p>

## Overview

The DSB Blogging Assistant automates blog post creation based on YouTube videos, leveraging advanced natural language processing capabilities provided by **Anthropic Claude (via AWS Bedrock)**. It also integrates **GitHub Actions** for CI/CD workflows to manage deployments and updates efficiently.

Key components include:

- **AWS Infrastructure**: Resources like Step Functions, Lambda, ECS, ECR, SNS, WAF, and SSM to manage the automation process.
- **Anthropic Claude via AWS Bedrock**: Used for generating blog post content from video transcripts.
- **Terraform Cloud**: Infrastructure as Code (IaC) for resource deployments.
- **GitHub Actions**: Automates CI/CD for Terraform deployments and Lambda image builds.
- **Python 3.12**: Handles custom logic for YouTube Poller and integrations.

## Project Architecture

### High-Level Architecture Diagram

![Architecture Diagram](./docs/images/architecture.drawio.svg)

#### How It Works

![Architecture Diagram](./docs/images/flow.drawio.svg)

1. A new video is uploaded to Damien's YouTube channel.
2. The YouTube Push Notification API sends an event to the ECS-based YouTube Poller service.
3. The poller triggers a Step Functions workflow with video metadata.
4. The workflow executes the following steps:
   - Download the video transcript.
   - Generate a blog post using Claude (Sonnet 3.5).
   - Commit the blog post to the `dsb-digest` GitHub repository.
   - Notify Damien via email.

## Setup Instructions

### Prerequisites

1. **Terraform Cloud**: Ensure you have access to Terraform Cloud and can configure variables and workspaces.
2. **AWS Credentials**: Set up AWS credentials with sufficient permissions.
3. **Python**: Install Python 3.12.
4. **AWS Bedrock Access**: Ensure that your AWS account has access to AWS Bedrock and the Anthropic Claude foundation model.

### Required Variables in Terraform Cloud

The following variables from `terraform/core/variables.tf` need to be saved in Terraform Cloud as **environment variables**:

| Variable Name          | Description                                   |
| ---------------------- | --------------------------------------------- |
| `GIT_USERNAME`         | Your GitHub username.                         |
| `GIT_AUTH_TOKEN`       | Personal access token for GitHub.             |
| `YOUTUBE_AUTH_TOKEN`   | YouTube API token.                            |
| `PROXY_USERNAME`       | Username for the proxy server.                |
| `PROXY_PASSWORD`       | Password for the proxy server.                |
| `EMAIL_ADDRESS`        | Email address for notifications.              |
| `YOUTUBE_TOPIC_URL`    | URL for the YouTube topic feed.               |
| `BLOG_GIT_REPO_URL`    | URL for Git Repository that hosts your blogs. |
| `YOUTUBE_CHANNEL_NAME` | YouTube Channel Name                          |

To set these variables in Terraform Cloud:

1. Navigate to the workspace connected to this repository.
2. Go to **Variables** > **Environment Variables**.
3. Add each variable and its corresponding value.

### Configuration Changes

#### 1. `provider.tf` File Updates

You need to replace the following placeholders in the `terraform/core/provider.tf` and other `provider.tf` files:

```hcl
terraform {
  cloud {
    workspaces {
      name = "dsb-blogging-assistant" # Replace this with your workspace name
    }
  }
}

provider "aws" {
  region = var.region
}
```

- Replace `DSB` with your Terraform Cloud organization name.
- Replace `dsb-blogging-assistant` with your workspace name in Terraform Cloud.
- Repeat steps for the other `provider.tf` files.

## GitHub Actions

### Setting Up Secrets

To configure secrets in your GitHub repository:

1. Go to **Settings > Secrets and Variables > Actions**.
1. Add the secrets listed below for the workflows.

### Terraform Apply Workflow

This workflow automates the application of Terraform configurations using Terraform Cloud.

**Required Secrets:**

| Secret Name             | Description                                                                                        |
| ----------------------- | -------------------------------------------------------------------------------------------------- |
| `TF_API_TOKEN`          | Terraform Cloud API token for authentication.                                                      |
| `TF_CLOUD_ORGANIZATION` | Terraform Cloud Organization (needs to align with the organization within your `provider.tf` file) |

### Docker Image Publisher Workflows (ECR)

This workflow builds and pushes the Lambda image to Amazon ECR if changes are detected in any of the lambdas subdirectories. Each Lambda sub directory has a Dockerfile associated and GitHub Action associated with it. You'll need to ensure that you have configured the following secrets.

**Required Secrets:**

| Secret Name             | Description                                       |
| ----------------------- | ------------------------------------------------- |
| `AWS_ACCESS_KEY_ID`     | AWS access key for programmatic access.           |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for programmatic access.           |
| `AWS_REGION`            | AWS region where the ECR repository is hosted.    |
| `AWS_ACCOUNT_ID`        | AWS account ID for ECR repository authentication. |

### Deployment Steps

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/The-DevSec-Blueprint/dsb-blogging-assistant.git
   cd dsb-blogging-assistant
   ```

2. **Set Up Terraform Cloud**:

   - Link this repository to a workspace in Terraform Cloud.
   - Add all required variables under **Environment Variables** in the workspace settings.
   - Make sure you create a role within AWS that can be used to deploy these resources with Terraform Cloud. Check out this blog post here: [Terraform Cloud with AWS](https://dev.to/aws-builders/terraform-cloud-with-aws-o20)
     > **NOTE**: I'd recommedn you use Variable Sets for your organization, and configure your access keys.

3. **Configure GitHub Secrets**:

   - Go to **Settings** > **Secrets and Variables** > **Actions** in your GitHub repository.
   - Add the required secrets listed above.

4. **Initialize Terraform**:

   - Move into both directories, `terraform/repositories` & `terraform/core`, and run the following command:

   ```bash
   export TF_CLOUD_ORGANIZATION="your_organization"
   terraform init
   ```

5. **Plan and Apply Changes**:

   - Move into both directories, `terraform/repositories` & `terraform/core`, and run the following command:

   ```bash
   terraform plan
   terraform apply
   ```

   > **NOTE**: Make sure you apply in the `repositories` directory first, build the docker images either via the GitHub Actions or locally and push them into the ECR repositories, and then apply the changes in the `core` directory.

6. **Verify Deployment**:
   - Check the AWS Console for deployed resources such as Step Functions, Lambda, ECS services, and SSM parameters.

## Troubleshooting

1. **GitHub Actions Failures**:

   - Verify that all required secrets are correctly configured in your repository.
   - Check the logs in the Actions tab for more details.

2. **Terraform Cloud Issues**:

   - Ensure the correct workspace and organization are set in `provider.tf`.
   - Verify that the `TF_API_TOKEN` secret is correct.

3. **AWS Bedrock Access**:
   - Confirm that your AWS account is configured for Bedrock and has access to the Anthropic Claude foundation model.

### Key Features of Anthropic Claude via AWS Bedrock

- **Advanced Language Understanding**: Claude generates high-quality blog posts from video transcripts.
- **Scalable and Serverless**: AWS Bedrock integrates seamlessly with Lambda and Step Functions for efficient and scalable execution.
- **Customizable**: Claude can be tailored to fit specific content styles and tones.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
