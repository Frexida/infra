# CloudWatch Log Group for CodeBuild
resource "aws_cloudwatch_log_group" "codebuild_logs" {
  name              = "/aws/codebuild/${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
  }
}

# SNS Topic for build failures
resource "aws_sns_topic" "build_failure" {
  name         = "${var.project_name}-build-failures"
  display_name = "CodeBuild Failure Notifications"

  tags = {
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.build_failure.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.ai_error_handler.arn
}

# CloudWatch Event Rule for build failures only
resource "aws_cloudwatch_event_rule" "codebuild_failure" {
  name        = "${var.project_name}-build-failure"
  description = "Trigger only when CodeBuild fails (not on success)"

  event_pattern = jsonencode({
    source      = ["aws.codebuild"]
    detail-type = ["CodeBuild Build State Change"]
    detail = {
      build-status = ["FAILED"] # Only trigger on failures
      project-name = [aws_codebuild_project.self_healing.name]
    }
  })

  tags = {
    Environment = var.environment
  }
}

resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.codebuild_failure.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.build_failure.arn
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.codebuild_failure.name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.ai_error_handler.arn
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "pipeline_monitoring" {
  dashboard_name = "${var.project_name}-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/CodeBuild", "Builds", { stat = "Sum", label = "Total Builds" }],
            [".", "SuccessfulBuilds", { stat = "Sum", label = "Successful" }],
            [".", "FailedBuilds", { stat = "Sum", label = "Failed" }]
          ]
          view   = "timeSeries"
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Build Status"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/CodeBuild", "Duration",
              { stat = "Average", label = "Avg Build Time (min)" },
              { stat = "Minimum", label = "Min Build Time (min)" },
              { stat = "Maximum", label = "Max Build Time (min)" }
            ]
          ]
          view   = "timeSeries"
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Build Duration"
          yAxis = {
            left = {
              label = "Minutes"
              min   = 0
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations",
            { stat = "Sum", label = "Lambda Invocations", dimensions = { FunctionName = aws_lambda_function.ai_error_handler.function_name } }],
            [".", "Errors",
            { stat = "Sum", label = "Lambda Errors", dimensions = { FunctionName = aws_lambda_function.ai_error_handler.function_name } }],
            [".", "Duration",
            { stat = "Average", label = "Avg Duration (ms)", dimensions = { FunctionName = aws_lambda_function.ai_error_handler.function_name } }]
          ]
          view   = "timeSeries"
          period = 300
          region = var.aws_region
          title  = "Lambda Metrics"
        }
      },
      {
        type = "log"
        properties = {
          query  = <<-EOT
            SOURCE '/aws/codebuild/${var.project_name}'
            | fields @timestamp, @message
            | filter @message like /ERROR|FAILED/
            | sort @timestamp desc
            | limit 20
          EOT
          region = var.aws_region
          title  = "Recent Errors"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["SelfHealingPipeline", "RetryCount",
            { stat = "Sum", label = "Total Retries" }],
            [".", "AIAgentInvocations",
            { stat = "Sum", label = "AI Agent Calls" }],
            [".", "PatchSuccessRate",
            { stat = "Average", label = "Patch Success Rate (%)" }]
          ]
          view   = "singleValue"
          period = 86400 # 1 day
          region = var.aws_region
          title  = "Daily Statistics"
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_failure_rate" {
  alarm_name          = "${var.project_name}-high-failure-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FailedBuilds"
  namespace           = "AWS/CodeBuild"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when build failure rate is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ProjectName = aws_codebuild_project.self_healing.name
  }

  alarm_actions = [aws_sns_topic.build_failure.arn]

  tags = {
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "infinite_loop_detection" {
  alarm_name          = "${var.project_name}-infinite-loop"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RetryCount"
  namespace           = "SelfHealingPipeline"
  period              = "3600" # 1 hour
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when too many retries occur"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.build_failure.arn]

  tags = {
    Environment = var.environment
  }
}

# Cost monitoring alarm
resource "aws_cloudwatch_metric_alarm" "cost_alert" {
  alarm_name          = "${var.project_name}-cost-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "21600" # 6 hours
  statistic           = "Maximum"
  threshold           = "20" # Alert at $20 (3000 JPY at ~150 JPY/USD)
  alarm_description   = "Alert when estimated charges exceed $20"

  dimensions = {
    Currency = "USD"
  }

  alarm_actions = [aws_sns_topic.build_failure.arn]

  tags = {
    Environment = var.environment
  }
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "build_failure_policy" {
  arn = aws_sns_topic.build_failure.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.build_failure.arn
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.build_failure.arn
      }
    ]
  })
}