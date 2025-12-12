###############################################################################
# Frexida Self-Healing CI/CD Pipeline
#
# GitHub Token is configured with the provided PAT
###############################################################################

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "frexida-terraform-state"
    key            = "self-healing-cicd/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
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

variable "github_repository" {
  description = "GitHub repository URL"
  type        = string
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "ai_agent_endpoint" {
  description = "AI Agent API endpoint URL"
  type        = string
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Self-healing CI/CD module with provided GitHub token
module "self_healing_cicd" {
  source = "../modules/self-healing-cicd"

  # Environment configuration
  environment = var.environment
  aws_region  = var.aws_region
  account_id  = data.aws_caller_identity.current.account_id

  # Project configuration
  project_name = "frexida-self-healing-pipeline"

  # GitHub configuration
  github_repository = var.github_repository
  github_branch     = "main"
  github_token      = var.github_token  # Set via environment variable

  # AI Agent configuration
  ai_agent_endpoint = var.ai_agent_endpoint
  # No API key needed for simple POST

  # Build configuration (optimized for cost)
  build_compute_type = "BUILD_GENERAL1_SMALL"  # 2 vCPU, 3GB RAM
  build_timeout      = 30                      # 30 minutes max
  max_retry_count    = 3                       # Max 3 automatic retries
  log_retention_days = 7                       # Keep logs for 7 days
}

###############################################################################
# Outputs
###############################################################################

output "webhook_url" {
  description = "GitHub webhook URL - Add this to your repository settings"
  value       = module.self_healing_cicd.webhook_url
  sensitive   = true
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL for monitoring"
  value       = module.self_healing_cicd.cloudwatch_dashboard_url
}

output "codebuild_project" {
  description = "CodeBuild project name"
  value       = module.self_healing_cicd.codebuild_project_name
}

output "lambda_function" {
  description = "Lambda function name for error handling"
  value       = module.self_healing_cicd.lambda_function_name
}

output "instructions" {
  value = <<-EOT

  ============================================================
  Self-Healing CI/CD Pipeline Setup Complete!
  ============================================================

  1. Get the webhook URL:
     terraform output -raw webhook_url

  2. Add webhook to GitHub:
     - Go to: ${var.github_repository}/settings/hooks
     - Click "Add webhook"
     - Paste the webhook URL
     - Content type: application/json
     - Select: Just the push event
     - Click "Add webhook"

  3. Add buildspec.yml to your repository root
     Copy from: modules/self-healing-cicd/buildspec.yml

  4. Monitor your pipeline:
     ${module.self_healing_cicd.cloudwatch_dashboard_url}

  5. Test by pushing code with an intentional error!

  ============================================================
  EOT
}