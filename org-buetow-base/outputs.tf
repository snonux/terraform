output "my_self_hosted_services_efs_id" {
  value = aws_efs_file_system.my_self_hosted_services_efs.id
}

output "my_public_subnet_a_id" {
  value = aws_subnet.my_public_subnet_a.id
}

output "my_public_subnet_b_id" {
  value = aws_subnet.my_public_subnet_b.id
}

output "my_public_subnet_c_id" {
  value = aws_subnet.my_public_subnet_c.id
}

output "allow_ssh_sg_id" {
  value = aws_security_group.allow_ssh.id
}

output "allow_web_sg_id" {
  value = aws_security_group.allow_web.id
}

output "allow_outbound_sg_id" {
  value = aws_security_group.allow_outbound.id
}
