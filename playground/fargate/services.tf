
## NGINX SERVICE (demo)

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

resource "aws_ecs_task_definition" "nginx_task" {
  family                   = "nginx"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "nginx",
    image = "nginx:latest",
    portMappings = [{
      containerPort = 80,
      hostPort      = 80
    }]
  }])
}

resource "aws_ecs_service" "nginx_service" {
  name            = "nginx-service"
  cluster         = aws_ecs_cluster.my_ecs_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task.arn
  launch_type     = "FARGATE"
  desired_count   = 2

  load_balancer {
    target_group_arn = aws_lb_target_group.my_nginx_tg.arn
    container_name   = "nginx" # Must match the name in your container definition
    container_port   = 80      # The port your container is listening on
  }

  network_configuration {
    subnets = [
      aws_subnet.my_public_subnet_a.id,
      aws_subnet.my_public_subnet_b.id,
      aws_subnet.my_public_subnet_c.id,
    ]
    security_groups  = [aws_security_group.web_sg.id]
    assign_public_ip = true
  }
}

resource "aws_lb_target_group" "my_nginx_tg" {
  name        = "my-nginx-tg"
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

resource "aws_lb_listener_rule" "my_nginx_https_listener_rule" {
  listener_arn = aws_lb_listener.my_https_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_nginx_tg.arn
  }

  condition {
    host_header {
      values = ["nginx.aws.buetow.org"]
    }
  }
}

## WALLABAG SERVICE (demo)

resource "aws_route53_record" "my_a_record_wallabag" {
  zone_id = data.aws_route53_zone.my_zone.zone_id
  name    = "bag.aws.buetow.org."
  type    = "A"

  alias {
    name                   = aws_lb.my_alb.dns_name
    zone_id                = aws_lb.my_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_ecs_task_definition" "wallabag_task" {
  family                   = "wallabag"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "wallabag",
    image = "wallabag/wallabag",
    portMappings = [{
      containerPort = 80,
      hostPort      = 80
    }],
    environment = [
      {
        name  = "SYMFONY__ENV__DOMAIN_NAME",
        value = "https://bag.aws.buetow.org"
      }
    ]
  }])
}

resource "aws_ecs_service" "wallabag_service" {
  name            = "wallabag-service"
  cluster         = aws_ecs_cluster.my_ecs_cluster.id
  task_definition = aws_ecs_task_definition.wallabag_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.my_wallabag_tg.arn
    container_name   = "wallabag" # Must match the name in your container definition
    container_port   = 80      # The port your container is listening on
  }

  network_configuration {
    subnets = [
      aws_subnet.my_public_subnet_a.id,
      aws_subnet.my_public_subnet_b.id,
      aws_subnet.my_public_subnet_c.id,
    ]
    security_groups  = [aws_security_group.web_sg.id]
    assign_public_ip = true
  }
}

resource "aws_lb_target_group" "my_wallabag_tg" {
  name        = "my-wallabag-tg"
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

resource "aws_lb_listener_rule" "my_wallabag_https_listener_rule" {
  listener_arn = aws_lb_listener.my_https_listener.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_wallabag_tg.arn
  }

  condition {
    host_header {
      values = ["bag.aws.buetow.org"]
    }
  }
}
