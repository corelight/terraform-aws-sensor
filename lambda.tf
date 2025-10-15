locals {
  script_name = "corelight_sensor_asg_nic_manager.py"
}

resource "aws_lambda_function" "auto_scaling_lambda" {
  function_name = var.lambda_function_name
  role          = var.asg_lambda_iam_role_arn
  filename      = "lambda_payload.zip"
  handler       = "corelight_sensor_asg_nic_manager.lambda_handler"
  timeout       = 30
  runtime       = "python3.12"

  source_code_hash = filebase64sha256(data.archive_file.aws_lambda_code.output_path)

  environment {
    variables = {
      TARGET_SUBNETS           = jsonencode({ for subnet in data.aws_subnet.management_subnets : subnet.availability_zone => subnet.id })
      TARGET_SECURITY_GROUP_ID = aws_security_group.management.id
    }
  }

  tags = var.tags

  depends_on = [
    data.archive_file.aws_lambda_code
  ]
}

data "archive_file" "aws_lambda_code" {
  output_path = "lambda_payload.zip"
  source_file = "${path.module}/scripts/${local.script_name}"
  type        = "zip"
}

resource "aws_cloudwatch_event_rule" "asg_lifecycle_rule" {
  name = var.eventbridge_lifecycle_rule_name
  event_pattern = jsonencode({
    "source" : ["aws.autoscaling"],
    "detail-type" : ["EC2 Instance-launch Lifecycle Action"],
    "detail" : {
      "AutoScalingGroupName" : [var.sensor_asg_name],
      "LifecycleHookName" : [var.asg_lifecycle_hook_name]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "${var.cloudwatch_log_group_prefix}/${aws_lambda_function.auto_scaling_lambda.function_name}"
  retention_in_days = var.cloudwatch_log_group_retention

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "ec2_state_change_rule_lambda_target" {
  arn  = aws_lambda_function.auto_scaling_lambda.arn
  rule = aws_cloudwatch_event_rule.asg_lifecycle_rule.name
}

resource "aws_lambda_permission" "ec2_state_change_event_bridge_trigger_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_scaling_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.asg_lifecycle_rule.arn
}
