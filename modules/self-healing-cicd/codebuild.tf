# CodeBuild Project
resource "aws_codebuild_project" "self_healing" {
  name          = var.project_name
  description   = "Self-healing CI/CD pipeline with AI-powered error correction"
  build_timeout = var.build_timeout
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = "${aws_s3_bucket.build_cache.id}/cache"
  }

  environment {
    compute_type                = var.build_compute_type
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

    environment_variable {
      name  = "AI_AGENT_ENDPOINT"
      value = var.ai_agent_endpoint
    }


    environment_variable {
      name  = "GITHUB_TOKEN"
      value = aws_secretsmanager_secret.github_token.arn
      type  = "SECRETS_MANAGER"
    }

    environment_variable {
      name  = "RETRY_COUNT"
      value = "0"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild_logs.name
      stream_name = "build-logs"
    }
  }

  source {
    type            = "GITHUB"
    location        = var.github_repository
    git_clone_depth = 1
    buildspec       = "buildspec.yml"

    git_submodules_config {
      fetch_submodules = false
    }
  }

  source_version = var.github_branch

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# S3 bucket for build cache
resource "aws_s3_bucket" "build_cache" {
  bucket = "frexida-codebuild-cache-${var.environment}"

  tags = {
    Environment = var.environment
    Purpose     = "CodeBuild cache"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "build_cache_lifecycle" {
  bucket = aws_s3_bucket.build_cache.id

  rule {
    id     = "delete-old-cache"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_public_access_block" "build_cache" {
  bucket = aws_s3_bucket.build_cache.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# GitHub webhook (commented out - configure manually in GitHub after deployment)
# Note: Webhook requires GitHub OAuth or Personal Access Token to be configured
# in AWS CodeBuild console first
# resource "aws_codebuild_webhook" "github" {
#   project_name = aws_codebuild_project.self_healing.name
#   build_type   = "BUILD"
#
#   filter_group {
#     filter {
#       type    = "EVENT"
#       pattern = "PUSH"
#     }
#
#     filter {
#       type    = "HEAD_REF"
#       pattern = "^refs/heads/${var.github_branch}$"
#     }
#   }
# }

# Secrets Manager for sensitive data (API key is optional)
resource "aws_secretsmanager_secret" "ai_agent_key" {
  count       = var.ai_agent_api_key != "" ? 1 : 0
  name        = "${var.project_name}/ai-agent-api-key"
  description = "AI Agent API key for self-healing pipeline"

  tags = {
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "ai_agent_key" {
  count         = var.ai_agent_api_key != "" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.ai_agent_key[0].id
  secret_string = var.ai_agent_api_key
}

resource "aws_secretsmanager_secret" "github_token" {
  name        = "${var.project_name}/github-token"
  description = "GitHub token for self-healing pipeline"

  tags = {
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "github_token" {
  secret_id     = aws_secretsmanager_secret.github_token.id
  secret_string = var.github_token
}

resource "aws_secretsmanager_secret" "webhook_secret" {
  count       = var.webhook_secret != "" ? 1 : 0
  name        = "${var.project_name}/webhook-secret"
  description = "GitHub webhook secret for validation"

  tags = {
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "webhook_secret" {
  count         = var.webhook_secret != "" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.webhook_secret[0].id
  secret_string = var.webhook_secret
}