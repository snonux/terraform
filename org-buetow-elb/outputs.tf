output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "alb_zone_id" {
  value = aws_lb.alb.zone_id
}

output "alb_https_listener_arn" {
  value = aws_lb_listener.https_listener.arn
}
