"""
Main handler module for the lambda function.
"""

import json
import logging
import boto3

logging.getLogger().setLevel(logging.INFO)


def redirect_to_step_functions(
    lambda_arn, statemachine_name, execution_name
):  # pylint: disable=line-too-long
    """
    This function will redirect the user to the Step Functions console.
    """
    lambda_arn_tokens = lambda_arn.split(":")
    partition = lambda_arn_tokens[1]
    region = lambda_arn_tokens[3]
    account_id = lambda_arn_tokens[4]

    execution_arn = f"arn:{partition}:states:{region}:{account_id}:execution:{statemachine_name}:{execution_name}"

    url = f"https://console.aws.amazon.com/states/home?region={region}#/executions/details/{execution_arn}"
    return {"statusCode": 302, "headers": {"Location": url}}


def main(event, context):
    """
    This function is triggered by a response to an email sent to the user.
    It will either confirm the video is technical or not.
    """
    logging.info("Triggered Event: %s", event)

    query_params = event.get("queryStringParameters", {})
    action = query_params.get("action")
    task_token = query_params.get("taskToken")
    statemachine_name = query_params.get("sm")
    execution_name = query_params.get("ex")

    stepfunctions = boto3.client("stepfunctions")

    if action == "yes":
        message = {"Status": "Video is confirmed as technical!"}
    elif action == "no":
        message = {"Status": "Video is confirmed as non-technical!"}
    else:
        logging.error("Unrecognized action. Expected: yes or no.")
        return {"Status": "Failed to process the request. Unrecognized Action."}

    stepfunctions.send_task_success(output=json.dumps(message), taskToken=task_token)
    return redirect_to_step_functions(
        context.invoked_function_arn, statemachine_name, execution_name
    )
