output "role_arn" {
  value = aws_iam_role.lambda_nic_manager_role.arn
}

output "role_name" {
  value = aws_iam_role.lambda_nic_manager_role.name
}

output "policy_arn" {
  value = aws_iam_policy.lambda_policy.arn
}


