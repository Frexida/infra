# Platform Self-Healing CI/CD Infrastructure

This directory contains the platform-level infrastructure for Frexida's self-healing CI/CD system.

## Overview

This is the **organization-wide CI/CD platform** that provides:
- Centralized error handling with AI-powered recovery
- Shared Lambda functions for all projects
- Common monitoring and alerting infrastructure
- Reusable CodeBuild configurations

## Architecture

```
┌──────────────────┐     ┌─────────────────┐     ┌──────────────────┐
│  GitHub Webhook  │────▶│  AWS CodeBuild  │────▶│  Build Success   │
└──────────────────┘     └─────────────────┘     └──────────────────┘
                                  │
                                  │ Failure
                                  ▼
                         ┌─────────────────┐
                         │  SNS Topic      │
                         └─────────────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │  Lambda Function│
                         └─────────────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │  AI Agent API   │
                         └─────────────────┘
```

## Resources Managed

- **Lambda Function**: `ai-error-handler` - Processes build failures
- **SNS Topics**: Build failure notifications
- **EventBridge Rules**: Trigger Lambda on CodeBuild failures
- **CloudWatch Dashboards**: Centralized monitoring
- **IAM Roles**: Service permissions
- **Secrets Manager**: API keys and tokens

## Prerequisites

1. **AWS Backend Infrastructure**:
   ```bash
   # S3 bucket for Terraform state
   aws s3 mb s3://frexida-terraform-state --region ap-northeast-1

   # DynamoDB table for state locking
   aws dynamodb create-table \
     --table-name terraform-lock \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region ap-northeast-1
   ```

2. **GitHub Actions OIDC**:
   ```bash
   # Create OIDC provider (if not exists)
   aws iam create-open-id-connect-provider \
     --url https://token.actions.githubusercontent.com \
     --client-id-list sts.amazonaws.com \
     --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
   ```

3. **IAM Role for GitHub Actions**:
   Use the template at `templates/iam/trust-policy-terraform-role.json`

## Deployment

### Via GitHub Actions (Recommended)

1. **Configure GitHub Secrets**:
   - `AWS_ROLE_ARN`: IAM role for OIDC authentication
   - `GH_PAT`: GitHub Personal Access Token
   - `AI_AGENT_API_KEY`: AI Agent API key (if required)

2. **Configure GitHub Variables**:
   - `AI_AGENT_ENDPOINT`: AI Agent API URL

3. **Push to main branch**:
   ```bash
   git push origin main
   ```
   The workflow will automatically deploy when changes are detected in:
   - `platform/` directory
   - `modules/` directory

### Manual Deployment

1. **Set environment variables**:
   ```bash
   export TF_VAR_github_token="ghp_..."
   export TF_VAR_ai_agent_endpoint="https://api.frexida.com/ci_result"
   export TF_VAR_ai_agent_api_key="optional-api-key"
   ```

2. **Initialize and apply**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## State Migration (If Upgrading)

If migrating from the old structure (`terraform/` directory):

1. **Backup existing state**:
   ```bash
   cd ../../terraform
   terraform state pull > ../backup-state.json
   ```

2. **Initialize new location**:
   ```bash
   cd ../platform/self-healing-cicd
   terraform init -reconfigure
   ```

3. **Import existing state**:
   ```bash
   terraform state push ../../backup-state.json
   ```

4. **Verify no changes**:
   ```bash
   terraform plan  # Should show no changes
   ```

## Configuration

### Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `TF_VAR_github_token` | GitHub PAT with repo permissions | Yes | - |
| `TF_VAR_github_repository` | GitHub repository URL | Yes | - |
| `TF_VAR_ai_agent_endpoint` | AI Agent API endpoint | Yes | - |
| `TF_VAR_ai_agent_api_key` | AI Agent API key | No | "" |
| `TF_VAR_github_webhook_secret` | Webhook validation secret | No | "" |
| `TF_VAR_environment` | Environment name | No | "production" |
| `TF_VAR_aws_region` | AWS region | No | "ap-northeast-1" |

### Cost Optimization

Current configuration is optimized for < 3,000 JPY/month:
- CodeBuild: BUILD_GENERAL1_SMALL (2 vCPU, 3GB RAM)
- Lambda: Within free tier
- CloudWatch Logs: 7-day retention
- DynamoDB: On-demand billing

## Monitoring

### CloudWatch Dashboard

Access the dashboard:
```bash
terraform output cloudwatch_dashboard_url
```

Metrics tracked:
- Build success/failure rates
- Lambda execution times
- Retry counts
- Cost estimates

### Alarms

Configured alarms:
- High failure rate (>50% in 5 minutes)
- Infinite retry loops (>5 retries)
- High costs (>3,000 JPY/month projected)

## Troubleshooting

### Common Issues

1. **State Lock Error**:
   ```bash
   # Force unlock if stuck
   terraform force-unlock <lock-id>
   ```

2. **OIDC Authentication Failed**:
   - Verify IAM role trust policy
   - Check GitHub Actions permissions
   - Ensure repository is in allowed list

3. **Lambda Function Not Triggering**:
   - Check EventBridge rule is enabled
   - Verify SNS subscription
   - Review Lambda permissions

### Debug Commands

```bash
# View Lambda logs
aws logs tail /aws/lambda/ai-error-handler --follow

# Check CodeBuild project
aws codebuild list-builds-for-project \
  --project-name frexida-app-pipeline

# Test Lambda locally
cd lambda/ai-error-handler
python index.py
```

## Maintenance

### Updating Lambda Function

1. Modify code in `lambda/ai-error-handler/`
2. Package and deploy:
   ```bash
   cd lambda/ai-error-handler
   zip -r lambda-package.zip .
   terraform apply -target=module.self_healing_cicd.aws_lambda_function.error_handler
   ```

### Rotating Secrets

```bash
# Update GitHub token
aws secretsmanager put-secret-value \
  --secret-id github-pat \
  --secret-string "new-token"

# Trigger Lambda to use new token
terraform apply -replace=module.self_healing_cicd.aws_lambda_function.error_handler
```

## Related Documentation

- [Module Documentation](../../modules/self-healing-cicd/README.md)
- [Project Configurations](../../projects/README.md)
- [Architecture Decision](../../docs/architecture-decision.md)