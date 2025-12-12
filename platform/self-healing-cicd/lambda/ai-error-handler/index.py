"""
AI Error Handler Lambda Function
Handles CodeBuild failures and sends error information to AI Agent API
"""

import json
import os
import boto3
import requests
from datetime import datetime, timedelta
from typing import Dict, Any, Optional
import time

# AWS clients
logs_client = boto3.client('logs')
secrets_client = boto3.client('secretsmanager')
codebuild_client = boto3.client('codebuild')
dynamodb = boto3.resource('dynamodb')
cloudwatch = boto3.client('cloudwatch')

# Configuration
AI_AGENT_ENDPOINT = os.environ['AI_AGENT_ENDPOINT']
MAX_RETRY_COUNT = int(os.environ.get('MAX_RETRY_COUNT', 3))
RETRY_TABLE = dynamodb.Table(os.environ['DYNAMODB_TABLE'])


def handler(event, context):
    """
    Handle CodeBuild failure events and send error information to AI agent
    """
    try:
        print(f"Received event: {json.dumps(event)}")

        # Parse event based on source (SNS or EventBridge)
        if 'Records' in event and event['Records'][0].get('EventSource') == 'aws:sns':
            # SNS message
            message = json.loads(event['Records'][0]['Sns']['Message'])
        else:
            # Direct EventBridge event
            message = event

        # Extract build information
        build_id = message['detail']['build-id']
        project_name = message['detail']['project-name']
        build_status = message['detail']['build-status']

        # Only process failures
        if build_status != 'FAILED':
            print(f"Build status is {build_status}, not processing")
            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'Not a failure, skipping'})
            }

        print(f"Processing build failure: {build_id}")
        print(f"Project: {project_name}, Status: {build_status}")

        # Check retry count to prevent infinite loops
        retry_count = get_retry_count(build_id)
        if retry_count >= MAX_RETRY_COUNT:
            print(f"Max retry count ({MAX_RETRY_COUNT}) reached for {build_id}. Stopping.")
            send_metric('MaxRetryReached', 1)
            send_max_retry_notification(build_id, project_name)
            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'Max retries exceeded'})
            }

        # Wait briefly for logs to be written
        time.sleep(3)

        # Get build metadata
        build_info = codebuild_client.batch_get_builds(ids=[build_id])
        build_metadata = build_info['builds'][0]

        # Retrieve error logs from CloudWatch
        log_group = f"/aws/codebuild/{project_name}"
        log_stream = build_id.split(':')[-1]

        error_logs = get_build_logs(log_group, log_stream)

        # Prepare simplified payload for AI agent
        agent_payload = {
            'buildStatus': 'FAILED',
            'buildId': build_id,
            'projectName': project_name,
            'logGroup': log_group,
            'logStream': log_stream,
            'errorLogs': error_logs,
            'commitHash': build_metadata.get('resolvedSourceVersion', '')[:7],
            'branch': build_metadata.get('sourceVersion', '').replace('refs/heads/', ''),
            'retryCount': retry_count,
            'timestamp': datetime.utcnow().isoformat() + 'Z'
        }

        print(f"Sending error information to AI agent: {AI_AGENT_ENDPOINT}")

        # Send to AI agent
        response = send_to_ai_agent(agent_payload)

        if response and response.status_code == 200:
            print("Successfully sent error information to AI agent")
            # Increment retry count for tracking
            increment_retry_count(build_id)
            send_metric('AIAgentNotified', 1)
        else:
            print(f"Failed to notify AI agent: {response.status_code if response else 'No response'}")
            send_metric('AIAgentNotificationFailed', 1)

        # Send metrics
        send_metric('BuildFailures', 1)
        send_metric('RetryCount', retry_count)

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Build failure processed'})
        }

    except Exception as e:
        print(f"Error processing build failure: {str(e)}")
        send_metric('LambdaErrors', 1)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }


def get_build_logs(log_group: str, log_stream: str, limit: int = 500) -> str:
    """
    Retrieve error logs from CloudWatch Logs
    """
    try:
        # Check if log stream exists
        response = logs_client.describe_log_streams(
            logGroupName=log_group,
            logStreamNamePrefix=log_stream,
            limit=1
        )

        if not response.get('logStreams'):
            print(f"Log stream {log_stream} not found")
            return "Log stream not yet available"

        # Get the last N log lines
        response = logs_client.get_log_events(
            logGroupName=log_group,
            logStreamName=log_stream,
            startFromHead=False,
            limit=limit
        )

        # Extract all log lines
        log_lines = [event['message'] for event in response.get('events', [])]

        # Filter for error-related lines (keep context)
        error_keywords = ['ERROR', 'FAILED', 'Error', 'error', 'npm ERR',
                         'pytest', 'FAIL', 'Exception', 'Traceback', 'fatal']

        error_lines = []
        include_next = 0

        for i, line in enumerate(log_lines):
            if any(keyword in line for keyword in error_keywords):
                # Include 3 lines before error for context
                for j in range(max(0, i-3), i):
                    if log_lines[j] not in error_lines:
                        error_lines.append(log_lines[j])
                error_lines.append(line)
                include_next = 5  # Include next 5 lines after error
            elif include_next > 0:
                error_lines.append(line)
                include_next -= 1

        # If no specific errors found, return last 100 lines
        if not error_lines:
            error_lines = log_lines[-100:]

        return '\n'.join(error_lines)

    except logs_client.exceptions.ResourceNotFoundException:
        print(f"Log group {log_group} not found")
        return f"Log group {log_group} not found"
    except Exception as e:
        print(f"Error retrieving logs: {str(e)}")
        return f"Error retrieving logs: {str(e)}"


def send_to_ai_agent(payload: Dict[str, Any]) -> Optional[requests.Response]:
    """
    Send error information to AI agent API
    Simple POST request with error details
    """
    try:
        headers = {
            'Content-Type': 'application/json'
        }

        # Optional: Add API key if configured
        api_key_arn = os.environ.get('AI_AGENT_API_KEY_ARN')
        if api_key_arn and api_key_arn != "":
            api_key = get_secret(api_key_arn)
            headers['Authorization'] = f'Bearer {api_key}'

        print(f"Sending POST request to: {AI_AGENT_ENDPOINT}")
        print(f"Payload size: {len(json.dumps(payload))} bytes")

        response = requests.post(
            AI_AGENT_ENDPOINT,
            json=payload,
            headers=headers,
            timeout=30  # 30 second timeout
        )

        print(f"AI agent response status: {response.status_code}")

        if response.status_code == 200:
            print("AI agent acknowledged the error notification")
        else:
            print(f"AI agent response: {response.text[:500]}")  # Log first 500 chars

        return response

    except requests.exceptions.Timeout:
        print("AI agent request timed out")
        return None
    except requests.exceptions.RequestException as e:
        print(f"Error calling AI agent: {str(e)}")
        return None
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        return None


def get_retry_count(build_id: str) -> int:
    """
    Get current retry count from DynamoDB
    """
    try:
        response = RETRY_TABLE.get_item(Key={'build_id': build_id})
        item = response.get('Item', {})
        return item.get('retry_count', 0)
    except Exception as e:
        print(f"Error getting retry count: {str(e)}")
        return 0


def increment_retry_count(build_id: str):
    """
    Increment retry count in DynamoDB with TTL
    """
    try:
        # Set expiration time to 24 hours from now
        expiration_time = int((datetime.now() + timedelta(hours=24)).timestamp())

        RETRY_TABLE.update_item(
            Key={'build_id': build_id},
            UpdateExpression='SET retry_count = if_not_exists(retry_count, :zero) + :inc, expiration_time = :exp',
            ExpressionAttributeValues={
                ':inc': 1,
                ':zero': 0,
                ':exp': expiration_time
            }
        )
        print(f"Incremented retry count for {build_id}")
    except Exception as e:
        print(f"Error updating retry count: {str(e)}")


def get_secret(secret_arn: str) -> str:
    """
    Retrieve secret from AWS Secrets Manager
    """
    try:
        response = secrets_client.get_secret_value(SecretId=secret_arn)
        return response['SecretString']
    except Exception as e:
        print(f"Error retrieving secret: {str(e)}")
        raise


def send_metric(metric_name: str, value: float, unit: str = 'Count'):
    """
    Send custom metric to CloudWatch
    """
    try:
        cloudwatch.put_metric_data(
            Namespace='SelfHealingPipeline',
            MetricData=[
                {
                    'MetricName': metric_name,
                    'Value': value,
                    'Unit': unit,
                    'Timestamp': datetime.utcnow()
                }
            ]
        )
    except Exception as e:
        print(f"Error sending metric {metric_name}: {str(e)}")


def send_max_retry_notification(build_id: str, project_name: str):
    """
    Send notification when max retries reached
    """
    try:
        # Log the event
        print(f"ALERT: Max retries reached for build {build_id} in project {project_name}")

        # Send a metric for alerting
        send_metric('MaxRetryExceeded', 1)

        # Could also send to SNS, Slack, etc. if configured
        # For now, just log it prominently

    except Exception as e:
        print(f"Error sending max retry notification: {str(e)}")