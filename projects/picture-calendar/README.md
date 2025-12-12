# Picture Calendar CI/CD Infrastructure

This directory contains the Terraform configuration for the picture-calendar project's self-healing CI/CD pipeline.

## Overview

The picture-calendar project uses the shared `self-healing-cicd` module to provision:
- AWS CodeBuild for automated builds
- Lambda function for error handling and automatic recovery
- SNS topics for build failure notifications
- CloudWatch monitoring and dashboards

## Prerequisites

1. AWS credentials configured (preferably via OIDC)
2. GitHub Personal Access Token with repo permissions
3. S3 backend bucket and DynamoDB table for state management

## Usage

### 1. Set Environment Variables

```bash
export TF_VAR_github_token="your-github-pat-token"
export TF_VAR_ai_agent_endpoint="https://api.frexida.com/ci_result"
# Optional: only if API requires authentication
export TF_VAR_ai_agent_api_key="your-ai-agent-api-key"
```

### 2. Initialize Terraform

```bash
cd terraform
terraform init
```

### 3. Plan and Apply

```bash
terraform plan
terraform apply
```

### 4. Configure GitHub Webhook

After applying Terraform, get the webhook URL:

```bash
terraform output -raw webhook_url
```

Add this URL to your GitHub repository:
1. Go to Settings > Webhooks
2. Add webhook with the URL
3. Select "Push" events
4. Content type: application/json

## Build Configuration

The build process is defined in the `buildspec.yml` file in the picture-calendar repository root. It includes:
- Python 3.11 runtime
- Build and test phases
- Automatic failure detection for branches containing "test-failure" or "fail"

## Monitoring

View the CloudWatch dashboard:

```bash
terraform output cloudwatch_dashboard_url
```

## Cost Optimization

- Build compute: BUILD_GENERAL1_SMALL (2 vCPU, 3GB RAM)
- Log retention: 7 days
- Estimated monthly cost: ~2,000-3,000 JPY

## Troubleshooting

### Build Failures
1. Check CloudWatch logs for the CodeBuild project
2. Review Lambda function logs for error handler execution
3. Verify GitHub webhook delivery status

### State Issues
If you encounter state locking issues:
```bash
aws dynamodb delete-item \
  --table-name terraform-lock \
  --key '{"LockID": {"S": "frexida-terraform-state/projects/picture-calendar/terraform.tfstate"}}'
```

## Related Documentation

- [Main Infrastructure Documentation](../../README.md)
- [Self-Healing CI/CD Module](../../modules/self-healing-cicd/README.md)
- [Platform Infrastructure](../../platform/self-healing-cicd/README.md)