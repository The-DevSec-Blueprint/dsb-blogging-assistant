# DSB Blogging Assistant

![Build Status](https://github.com/The-DevSec-Blueprint/dsb-blogging-assistant/actions/workflows/default_workflow.yml/badge.svg?logo=github)
![License](https://img.shields.io/github/license/The-DevSec-Blueprint/dsb-blogging-assistant?logo=license)
![Terraform Registry](https://img.shields.io/badge/Terraform-Registry-purple?logo=terraform)
![Python Requirements](https://img.shields.io/badge/python-3.8-blue?logo=python)
![GitHub Issues](https://img.shields.io/github/issues/The-DevSec-Blueprint/dsb-blogging-assistant?logo=github)
![GitHub Forks](https://img.shields.io/github/forks/The-DevSec-Blueprint/dsb-blogging-assistant?logo=github)
![GitHub Stars](https://img.shields.io/github/stars/The-DevSec-Blueprint/dsb-blogging-assistant?logo=github)
![GitHub Last Commit](https://img.shields.io/github/last-commit/The-DevSec-Blueprint/dsb-blogging-assistant?logo=github)

<p align="center"><img src="./docs/images/logo.svg" /></p>

## Overview

This is the super duper awesome framework that I've built to help automate the creation of blog posts based on my YouTube videos. Knocking out two birds with one stone!

For this particular framework, I am using the following tools and technologies:

- Amazon Web Services (AWS) - Several services within AWS such as Step Functions, ECR, Lambda, etc.
- Docker - Containerized Applications that are deployed to AWS for hosting/management.
- Terraform Cloud - IaC deployment into AWS
- Python 3.12 - Custom code for both the YouTube Poller and the core-lambda function that interacts with ChatGPT

## Architecture Diagrams and Flows

### Base Level Architecture Diagram

>**NOTE**: This architecture diagram is out of date. The ALB does not exist, or has been decommissioned.
![Base Architecture Diagram](./docs/images/architecture.drawio.svg)

#### Detailed Explanation _(Somewhat)_

This is the base-level architecture diagram that gives you a high-level overview of what/how things are deployed into this account. For starters, we use Terraform Cloud to deploy all of the necessary components into the `ca-central-1` region within AWS. The following resources are deployed:

- SNS Topic for emailing
- 2 ECR Repositories
- Step Function
- Lambda Function
- ECR Cluster with Task Definitions
- Application Load Balancer
- SSM Parameters for managing API keys and secrets
- IAM Roles and Policies (no brainer)

So, when we _(and I mean me)_ make updates to the codebase, the GitHub action will trigger a workflow that deploys the latest code changes to the ECR repositories, and then perform a Terraform Apply, focusing the lambda function and ECR cluster to update and use the latest image.

### Use Case Architecture Flow Diagram

![Flow Diagram - the awesomeness!](./docs/images/flow.drawio.svg)

#### Flow Diagram Explained

1. Damien uploads a new video to his YouTube channel.
1. He publishes the video, and the PubSubHubBub process will send an event to the subscribed ECS cluster or service called YouTube Poller.
1. The poller will take the key information, like video title and url, and trigger the step function by passing in the payload.
1. The step function will trigger the lambda function and execute a series of states.
1. First state: The transcript from the video will be downloaded.
1. Second State: The transcript will be send to ChatGPT with a custom message to generate the blog post in markdown format.
1. Third State: The `dsb-digest` repository will be cloned, and the contents of the new blog post will be committed and checked in on a new branch (hashed value of the title).
1. Final State: The step function/lambda function wraps up and send the final payload over to the SNS topic.
1. An email will be sent out with the necessary information for Damien to identify the blog post in the `dsb-digest` repository.

## Installation Instructions

I mean, you shouldn't have forgotten how to install your own shit, but if you did, just do the following:

1. Initiatize Terraform
1. Create Virtual Environment in Python
1. Install Python Dependencies
1. Check the GitHub Actions and all of your API key references
1. Log into Terraform Cloud using your GitHub OAuth Token
1. Trigger the plan either in the console or via CLI

You're done.

## Engineering Notes

- If you forget how to configure your Terraform Cloud account and map it to your repository, just take a look at this page: <https://developer.hashicorp.com/terraform/tutorials/automation/github-actions>

## References

- <https://developers.google.com/youtube/v3/guides/push_notifications>
- <https://github.com/BryanCuneo/yt-to-discord/tree/main?tab=readme-ov-file>

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.