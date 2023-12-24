resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups = [
    data.terraform_remote_state.base.outputs.allow_web_sg_id,
    data.terraform_remote_state.base.outputs.allow_outbound_sg_id,
  ]
  ip_address_type = "dualstack"
  subnets = [
    data.terraform_remote_state.base.outputs.public_subnet_a_id,
    data.terraform_remote_state.base.outputs.public_subnet_b_id,
    data.terraform_remote_state.base.outputs.public_subnet_c_id,
  ]
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
      path        = "/#{path}"
      query       = "#{query}"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.terraform_remote_state.base.outputs.buetow_cloud_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default_tg.arn
  }
}

resource "aws_lb_target_group" "default_tg" {
  name        = "default-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id
  target_type = "ip"
}

