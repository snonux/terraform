resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.my_public_subnet_a.id,
    aws_subnet.my_public_subnet_b.id,
    aws_subnet.my_public_subnet_c.id,
  ]

  enable_deletion_protection = false
}

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "my_tg" {
  name        = "my-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.my_vpc.id
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

resource "aws_lb_listener" "my_http_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tg.arn
  }
}

data "aws_route53_zone" "my_zone" {
  name = "aws.buetow.org."
}

resource "aws_route53_record" "my_a_record" {
  zone_id = data.aws_route53_zone.my_zone.zone_id
  name    = "nginx.aws.buetow.org."
  type    = "A"

  alias {
    name                   = aws_lb.my_alb.dns_name
    zone_id                = aws_lb.my_alb.zone_id
    evaluate_target_health = true
  }
}

#resource "aws_route53_record" "my_aaaa_record" {
#  zone_id = data.aws_route53_zone.my_zone.zone_id
#  name    = "nginx.aws.buetow.org."
#  type    = "AAAA"
#
#  alias {
#    name                   = aws_lb.my_alb.dns_name
#    zone_id                = aws_lb.my_alb.zone_id
#    evaluate_target_health = true
#  }
#}


#resource "aws_lb_listener" "my_https_listener" {
#  load_balancer_arn = aws_lb.my_alb.arn
#  port              = "443"
#  protocol          = "HTTPS"
#
#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.my_tg.arn
#  }
#}

