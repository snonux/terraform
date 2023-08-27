output "name_servers" {
  value = aws_route53_zone.my_zone.name_servers
}

output "public_ip" {
  value = aws_instance.my_instance.public_ip
}
