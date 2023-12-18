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
    }],
    "logConfiguration" : {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-group" : "/ecs/containers",
        "awslogs-region" : "eu-central-1",
        "awslogs-stream-prefix" : "nginx"
      }
    }
  }])
}

resource "aws_ecs_service" "nginx_service" {
  name            = "nginx-service"
  cluster         = aws_ecs_cluster.my_ecs_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task.arn
  launch_type     = "FARGATE"
  desired_count   = 10

  load_balancer {
    target_group_arn = aws_lb_target_group.my_nginx_tg.arn
    container_name   = "nginx" # Must match the name in your container definition
    container_port   = 80      # The port your container is listening on
  }

  network_configuration {
    subnets = [
      data.terraform_remote_state.base.outputs.my_public_subnet_a_id,
      data.terraform_remote_state.base.outputs.my_public_subnet_b_id,
      data.terraform_remote_state.base.outputs.my_public_subnet_c_id,
    ]
    security_groups  = [data.terraform_remote_state.base.outputs.allow_web_sg_id]
    assign_public_ip = true
  }
}

resource "aws_lb_target_group" "my_nginx_tg" {
  name        = "my-nginx-tg"
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
