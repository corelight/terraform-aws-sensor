data "aws_iam_policy_document" "multi_eni_lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.log_group.arn}:*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeInstances",
      "ec2:DescribeSubnets",
      "autoscaling:DescribeAutoScalingGroups"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction"
    ]
    resources = [aws_autoscaling_group.sensor_asg.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DetachNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:AttachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = ["true"]
      variable = "aws:ResourceTag/CorelightManaged"
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:CreateTags",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  policy = data.aws_iam_policy_document.multi_eni_lambda_policy.json

  tags = var.tags
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "multi_eni_role" {
  name               = var.iam_lambda_role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.multi_eni_role.id
}


