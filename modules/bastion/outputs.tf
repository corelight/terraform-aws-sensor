output "bastion_instance_id" {
  value = aws_instance.bastion.id
}

output "bastion_ssh_security_group_arn" {
  value = aws_security_group.allow_ssh.arn
}

output "bastion_nic_arn" {
  value = aws_network_interface.bastion_nic.arn
}

output "bastion_eip_id" {
  value = aws_eip.bastion_public_ip.id
}