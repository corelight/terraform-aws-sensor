data "aws_partition" "current" {}

data "aws_iam_policy_document" "lambda_nic_manager_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${var.lambda_cloudwatch_log_group_arn}:*"
    ]
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
    resources = [
      var.sensor_autoscaling_group_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:*:*:instance/*"
    ]
    condition {
      test     = "StringEquals"
      values   = [split("/", var.sensor_autoscaling_group_arn)[1]]
      variable = "aws:ResourceTag/aws:autoscaling:groupName"
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DetachNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:AttachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:*:*:network-interface/*"
    ]
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
    resources = concat(
      var.subnet_arns,
      [
        var.security_group_arn,
        "arn:${data.aws_partition.current.partition}:ec2:*:*:network-interface/*"
      ]
    )
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = var.lambda_policy_name
  policy = data.aws_iam_policy_document.lambda_nic_manager_policy.json

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

resource "aws_iam_role" "lambda_nic_manager_role" {
  name               = var.lambda_role_arn
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_nic_manager_role.name
}
