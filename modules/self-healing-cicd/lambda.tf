# Lambda function for AI error handling
resource "aws_lambda_function" "ai_error_handler" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-ai-error-handler"
  role             = aws_iam_role.lambda_ai_handler.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = 60
  memory_size      = 512

  environment {
    variables = {
      AI_AGENT_ENDPOINT    = var.ai_agent_endpoint
      AI_AGENT_API_KEY_ARN = var.ai_agent_api_key != "" ? aws_secretsmanager_secret.ai_agent_key[0].arn : ""
      GITHUB_TOKEN_ARN     = aws_secretsmanager_secret.github_token.arn
      WEBHOOK_SECRET_ARN   = var.webhook_secret != "" ? aws_secretsmanager_secret.webhook_secret[0].arn : ""
      CODEBUILD_PROJECT    = aws_codebuild_project.self_healing.name
      MAX_RETRY_COUNT      = var.max_retry_count
      DYNAMODB_TABLE       = aws_dynamodb_table.retry_tracking.name
    }
  }

  tags = {
    Environment = var.environment
  }
}

# Package Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambda/ai-error-handler"
  output_path = "${path.module}/lambda-package.zip"
}

# Lambda permission for SNS
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ai_error_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.build_failure.arn
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ai_error_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.codebuild_failure.arn
}

# DynamoDB table for retry tracking
resource "aws_dynamodb_table" "retry_tracking" {
  name         = "${var.project_name}-retry-tracking"
  billing_mode = "PAY_PER_REQUEST" # On-demand for cost optimization
  hash_key     = "build_id"

  attribute {
    name = "build_id"
    type = "S"
  }

  ttl {
    attribute_name = "expiration_time"
    enabled        = true
  }

  tags = {
    Environment = var.environment
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-ai-error-handler"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
  }
}