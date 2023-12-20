output "self_hosted_services_efs_id" {
  value = aws_efs_file_system.self_hosted_services_efs.id
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_a_id" {
  value = aws_subnet.public_subnet_a.id
}

output "public_subnet_b_id" {
  value = aws_subnet.public_subnet_b.id
}

output "public_subnet_c_id" {
  value = aws_subnet.public_subnet_c.id
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

output "aws_buetow_org_zone_id" {
  value = aws_route53_zone.aws_buetow_org.zone_id
}

output "aws_buetow_org_certificate_arn" {
  value = "arn:aws:acm:eu-central-1:634617747016:certificate/4ae442c0-3b56-4e17-9a3f-023faf39d244"
}
