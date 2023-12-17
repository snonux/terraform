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

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_lb_listener" "my_http_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
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

data "aws_route53_zone" "my_zone" {
  name = "aws.buetow.org."
}

resource "aws_lb_listener" "my_https_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  # aws.buetow.org and *.aws.buetow.org certificate.
  certificate_arn = "arn:aws:acm:eu-central-1:634617747016:certificate/4ae442c0-3b56-4e17-9a3f-023faf39d244"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_nginx_tg.arn
  }
}
