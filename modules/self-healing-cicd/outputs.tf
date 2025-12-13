output "codebuild_project_name" {
  description = "CodeBuild project name"
  value       = aws_codebuild_project.self_healing.name
}

output "codebuild_project_arn" {
  description = "CodeBuild project ARN"
  value       = aws_codebuild_project.self_healing.arn
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.ai_error_handler.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.ai_error_handler.arn
}

output "sns_topic_arn" {
  description = "SNS topic ARN for build failures"
  value       = aws_sns_topic.build_failure.arn
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name (dashboard temporarily disabled)"
  value       = "${var.project_name}-monitoring"
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL (dashboard temporarily disabled)"
  value       = "Dashboard temporarily disabled - will be created manually"
}

output "build_cache_bucket" {
  description = "S3 bucket for build cache"
  value       = aws_s3_bucket.build_cache.id
}

output "webhook_url" {
  description = "GitHub webhook URL (manually configure in GitHub after deployment)"
  value       = "Webhook must be manually configured in GitHub after CodeBuild project is created"
  sensitive   = false
}

output "webhook_secret" {
  description = "GitHub webhook secret ARN"
  value       = var.webhook_secret != "" ? aws_secretsmanager_secret.webhook_secret[0].arn : ""
  sensitive   = true
}

output "retry_tracking_table" {
  description = "DynamoDB table name for retry tracking"
  value       = aws_dynamodb_table.retry_tracking.name
}

output "codebuild_service_role_arn" {
  description = "CodeBuild service role ARN"
  value       = aws_iam_role.codebuild_role.arn
}

output "lambda_execution_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_ai_handler.arn
}