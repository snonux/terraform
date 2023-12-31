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

output "zone_id" {
  value = data.aws_route53_zone.buetow_cloud.zone_id
}

output "zone_name" {
  value = data.aws_route53_zone.buetow_cloud.name
}

output "zone_certificate_arn" {
  # For buetow.cloud and *.buetow.cloud
  value = "arn:aws:acm:eu-central-1:634617747016:certificate/fbf5627c-9a4c-4c62-9c33-038e140f3f12"
}
