###############################################################################
# Self-Healing CI/CD Pipeline Configuration
#
# This configuration creates a self-healing CI/CD pipeline with:
# - AWS CodeBuild for builds
# - AI-powered automatic error correction
# - Cost optimization (target: < 3000 JPY/month)
###############################################################################

# Variables for sensitive data (set via environment variables or terraform.tfvars)
variable "ai_agent_api_key" {
  description = "API key for AI agent service (optional - only if API requires auth)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_token" {
  description = "GitHub personal access token with repo permissions"
  type        = string
  sensitive   = true
}

variable "github_webhook_secret" {
  description = "Secret for GitHub webhook validation (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Self-healing CI/CD module
module "self_healing_cicd" {
  source = "../modules/self-healing-cicd"

  # Environment configuration
  environment = var.environment
  aws_region  = var.aws_region
  account_id  = data.aws_caller_identity.current.account_id

  # Project configuration
  project_name = "frexida-app-pipeline"

  # GitHub configuration
  github_repository = "https://github.com/Frexida/app-foobar.git"
  github_branch     = "main"
  github_token      = var.github_token
  webhook_secret    = var.github_webhook_secret

  # AI Agent configuration
  ai_agent_endpoint = "https://api.frexida.com/ci_result"
  ai_agent_api_key  = var.ai_agent_api_key

  # Build configuration (optimized for cost)
  build_compute_type = "BUILD_GENERAL1_SMALL"  # 2 vCPU, 3GB RAM
  build_timeout      = 30                      # 30 minutes max
  max_retry_count    = 3                       # Max 3 automatic retries

  # Cost optimization settings
  log_retention_days = 7  # Keep logs for only 7 days to reduce costs
}

###############################################################################
# Outputs
###############################################################################

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = module.self_healing_cicd.codebuild_project_name
}

output "webhook_url" {
  description = "GitHub webhook URL (add this to your repository settings)"
  value       = module.self_healing_cicd.webhook_url
  sensitive   = true
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL for monitoring"
  value       = module.self_healing_cicd.cloudwatch_dashboard_url
}

output "lambda_function_name" {
  description = "Name of the Lambda function for error handling"
  value       = module.self_healing_cicd.lambda_function_name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for build failure notifications"
  value       = module.self_healing_cicd.sns_topic_arn
}

###############################################################################
# Usage Instructions
###############################################################################
#
# 1. Set environment variables:
#    export TF_VAR_github_token="your-github-token"
#    export TF_VAR_ai_agent_api_key="your-api-key" # Optional - only if API requires auth
#    export TF_VAR_github_webhook_secret="optional-webhook-secret"
#
# 2. Initialize and apply Terraform:
#    terraform init
#    terraform plan
#    terraform apply
#
# 3. Add webhook to GitHub repository:
#    - Go to your repository Settings > Webhooks
#    - Add the webhook URL from the output
#    - Select "Push" events
#    - Set content type to "application/json"
#
# 4. Add buildspec.yml to your repository root:
#    - Copy modules/self-healing-cicd/buildspec.yml to your repo
#    - Customize for your project's build requirements
#
# 5. Monitor the pipeline:
#    - View the CloudWatch dashboard URL from the output
#    - Check build logs in CodeBuild console
#    - View Lambda logs for AI agent interactions
#
# Cost Breakdown (estimated monthly):
# - CodeBuild: ~1,875 JPY (500 builds @ 5 min each)
# - CloudWatch Logs: ~84 JPY (1GB ingestion, 7-day retention)
# - Secrets Manager: ~60 JPY (1 secret for GitHub token only)
# - Lambda: < 1 JPY (within free tier)
# - DynamoDB: < 10 JPY (on-demand, minimal usage)
# - Total: ~2,030 JPY/month (well under 3,000 JPY budget)
#
###############################################################################