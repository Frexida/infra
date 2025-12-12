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
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.pipeline_monitoring.dashboard_name
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.pipeline_monitoring.dashboard_name}"
}

output "build_cache_bucket" {
  description = "S3 bucket for build cache"
  value       = aws_s3_bucket.build_cache.id
}

output "webhook_url" {
  description = "GitHub webhook URL"
  value       = aws_codebuild_webhook.github.payload_url
  sensitive   = true
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