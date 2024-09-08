# DSB Blogging Assistant

![Build Status](https://github.com/The-DevSec-Blueprint/dsb-blogging-assistant/actions/workflows/default_workflow.yml/badge.svg?logo=github)
![License](https://img.shields.io/github/license/The-DevSec-Blueprint/dsb-blogging-assistant?logo=license)
![Terraform Registry](https://img.shields.io/badge/Terraform-Registry-purple?logo=terraform)
![Python Requirements](https://img.shields.io/badge/python-3.12-blue?logo=python)
![GitHub Issues](https://img.shields.io/github/issues/The-DevSec-Blueprint/dsb-blogging-assistant?logo=github)
![GitHub Forks](https://img.shields.io/github/forks/The-DevSec-Blueprint/dsb-blogging-assistant?logo=github)
![GitHub Stars](https://img.shields.io/github/stars/The-DevSec-Blueprint/dsb-blogging-assistant?logo=github)
![GitHub Last Commit](https://img.shields.io/github/last-commit/The-DevSec-Blueprint/dsb-blogging-assistant?logo=github)

<p align="center"><img src="./docs/images/logo.svg" /></p>

## Overview

The DSB Blogging Assistant is a framework designed to automate the creation of blog posts based on YouTube videos, streamlining the content creation process. It integrates several tools and technologies to simplify workflow automation.

This framework leverages:

- **Amazon Web Services (AWS):** Utilizing various services such as Step Functions, ECR, Lambda, etc.
- **Docker:** Containerized applications deployed to AWS for hosting and management.
- **Terraform Cloud:** Infrastructure as Code (IaC) for deploying resources into AWS.
- **Python 3.12:** Custom code for the YouTube Poller and the core Lambda function that interacts with ChatGPT.

## Architecture Diagrams and Flows

### Base-Level Architecture Diagram

> **Note:** This diagram is outdated. The ALB has been decommissioned.  
![Base Architecture Diagram](./docs/images/architecture.drawio.svg)

#### Explanation

The base architecture diagram provides a high-level overview of how components are deployed. Terraform Cloud is used to provision all necessary resources in the `ca-central-1` region within AWS. The following resources are deployed:

- SNS Topic for email notifications
- Two ECR Repositories
- Step Function
- Lambda Function
- ECS Cluster with Task Definitions
- Application Load Balancer
- SSM Parameters for managing API keys and secrets
- IAM Roles and Policies

Upon code updates, a GitHub action triggers a workflow to deploy the latest changes to the ECR repositories, followed by a Terraform Apply to update the Lambda function and ECS cluster.

### Use Case Architecture Flow Diagram

![Flow Diagram](./docs/images/flow.drawio.svg)

#### Flow Diagram Overview

1. A new video is uploaded to Damien's YouTube channel.
2. Once published, the PubSubHubBub process sends an event to the ECS cluster's YouTube Poller service.
3. The poller extracts key information such as video title and URL, triggering a Step Function by passing the payload.
4. The Step Function initiates the Lambda function, executing a series of steps:
   - **Step 1:** The video transcript is downloaded.
   - **Step 2:** The transcript is sent to ChatGPT with a request to generate a blog post in markdown format.
   - **Step 3:** The `dsb-digest` repository is cloned, and the new blog post is committed to a new branch based on a hashed value of the video title.
   - **Final Step:** The process concludes, and the final payload is sent to the SNS topic.
5. An email is sent to Damien with details about the new blog post in the `dsb-digest` repository.

## Installation Instructions

Follow these steps to install and configure the framework:

1. Initialize Terraform.
2. Create a Python virtual environment.
3. Install Python dependencies.
4. Verify your GitHub Actions and API key references.
5. Log in to Terraform Cloud using your GitHub OAuth token.
6. Trigger the Terraform plan either through the console or CLI.

Installation is complete.

## Engineering Notes

If you need to reconfigure your Terraform Cloud account or map it to your repository, refer to the following guide:  
<https://developer.hashicorp.com/terraform/tutorials/automation/github-actions>

## References

- YouTube Push Notifications: <https://developers.google.com/youtube/v3/guides/push_notifications>
- Related project: <https://github.com/BryanCuneo/yt-to-discord/tree/main?tab=readme-ov-file>

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
