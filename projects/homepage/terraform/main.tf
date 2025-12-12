###############################################################################
# Frexida Homepage CI/CD Infrastructure
#
# This configuration creates a self-healing CI/CD pipeline for the
# homepage project using the shared self-healing-cicd module.
###############################################################################

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "github_webhook_secret" {
  description = "Secret for GitHub webhook validation (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ai_agent_endpoint" {
  description = "AI Agent API endpoint URL"
  type        = string
  default     = "https://api.frexida.com/ci_result"
}

variable "ai_agent_api_key" {
  description = "API key for AI agent service (optional)"
  type        = string
  sensitive   = true
  default     = ""
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Self-healing CI/CD module for homepage
module "homepage_cicd" {
  source = "../../../modules/self-healing-cicd"

  # Environment configuration
  environment = var.environment
  aws_region  = var.aws_region
  account_id  = data.aws_caller_identity.current.account_id

  # Project configuration
  project_name = "homepage"

  # GitHub configuration
  github_repository = "https://github.com/Frexida/homepage.git"
  github_branch     = "main"
  github_token      = var.github_token
  webhook_secret    = var.github_webhook_secret

  # AI Agent configuration
  ai_agent_endpoint = var.ai_agent_endpoint
  ai_agent_api_key  = var.ai_agent_api_key

  # Build configuration (optimized for cost)
  build_compute_type = "BUILD_GENERAL1_SMALL"  # 2 vCPU, 3GB RAM
  build_timeout      = 30                      # 30 minutes max
  max_retry_count    = 3                       # Max 3 automatic retries
  log_retention_days = 7                       # Keep logs for 7 days
}

###############################################################################
# Outputs
###############################################################################

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = module.homepage_cicd.codebuild_project_name
}

output "webhook_url" {
  description = "GitHub webhook URL - Add this to your repository settings"
  value       = module.homepage_cicd.webhook_url
  sensitive   = true
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL for monitoring"
  value       = module.homepage_cicd.cloudwatch_dashboard_url
}

output "lambda_function_name" {
  description = "Name of the Lambda function for error handling"
  value       = module.homepage_cicd.lambda_function_name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for build failure notifications"
  value       = module.homepage_cicd.sns_topic_arn
}