# IAM Role
An AWS IAM role needs to be created with the following assume role policy and permissions

# Assume Role Policy
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}

```

# Permissions

```json
{
    "Statement": [
        {
            "Action": [
                "logs:PutLogEvents",
                "logs:CreateLogStream"
            ],
            "Effect": "Allow",
            "Resource": "{ARN of the log group the ASG Lambda will use to create streams and write logs}:*"
        },
        {
            "Action": [
                "ec2:DescribeSubnets",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeInstances",
                "autoscaling:DescribeAutoScalingGroups"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": "autoscaling:CompleteLifecycleAction",
            "Effect": "Allow",
            "Resource": "{ARN of the sensor EC2 autoscaling group of Corelight sensors}"
        },
        {
            "Action": [
                "ec2:ModifyNetworkInterfaceAttribute",
                "ec2:AttachNetworkInterface"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/aws:autoscaling:groupName": "{name of the Corelight sensor autoscaling group}"
                }
            },
            "Effect": "Allow",
            "Resource": "arn:aws:ec2:*:*:instance/*"
        },
        {
            "Action": [
                "ec2:ModifyNetworkInterfaceAttribute",
                "ec2:DetachNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:AttachNetworkInterface"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/CorelightManaged": "true"
                }
            },
            "Effect": "Allow",
            "Resource": "arn:aws:ec2:*:*:network-interface/*"
        },
        {
            "Action": [
                "ec2:CreateTags",
                "ec2:CreateNetworkInterface"
            ],
            "Effect": "Allow",
            "Resource": [
                "{ARN of the subnet where new ENIs should be created. Typically your management subnet}",
                "{ARN of the security group that should be associated with newly created ENIs. Typically management sg}",
                "arn:aws:ec2:*:*:network-interface/*"
            ]
        }
    ],
    "Version": "2012-10-17"
}
```