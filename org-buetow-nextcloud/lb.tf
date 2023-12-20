resource "aws_route53_record" "my_a_record" {
  zone_id = data.aws_route53_zone.my_zone.zone_id
  name    = "nextcloud.aws.buetow.org."
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.elb.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.elb.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb_target_group" "nextcloud_tg" {
  name        = "nextcloud-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.base.outputs.my_vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    path                = "/" # Modify if your app has a specific health check path
    protocol            = "HTTP"
    timeout             = 3
    matcher             = "200-299"
  }
}

resource "aws_lb_listener_rule" "nextcloud_https_listener_rule" {
  listener_arn = data.terraform_remote_state.elb.outputs.alb_https_listener_arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nextcloud_tg.arn
  }

  condition {
    host_header {
      values = ["nextcloud.aws.buetow.org"]
    }
  }
}
