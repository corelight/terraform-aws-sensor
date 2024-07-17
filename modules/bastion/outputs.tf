output "bastion_instance_id" {
  value = aws_instance.bastion.id
}

output "bastion_ssh_security_group_arn" {
  value = aws_security_group.bastion_sg.arn
}