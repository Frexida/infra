variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
}

variable "project_name" {
  description = "CodeBuild project name"
  type        = string
  default     = "self-healing-pipeline"
}

variable "github_repository" {
  description = "GitHub repository URL"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to build"
  type        = string
  default     = "main"
}

variable "ai_agent_endpoint" {
  description = "AI Agent API endpoint URL"
  type        = string
}

variable "ai_agent_api_key" {
  description = "AI Agent API key (optional - only if your API requires authentication)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "build_compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "build_timeout" {
  description = "Build timeout in minutes"
  type        = number
  default     = 30
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period"
  type        = number
  default     = 7
}

variable "max_retry_count" {
  description = "Maximum number of auto-retry attempts"
  type        = number
  default     = 3
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "webhook_secret" {
  description = "GitHub webhook secret for validation"
  type        = string
  sensitive   = true
  default     = ""
}