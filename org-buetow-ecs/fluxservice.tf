resource "aws_route53_record" "a_record_flux" {
  zone_id = data.terraform_remote_state.base.outputs.zone_id
  name    = "flux.${data.terraform_remote_state.base.outputs.zone_name}."
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.elb.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.elb.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "aaaa_record_flux" {
  zone_id = data.terraform_remote_state.base.outputs.zone_id
  name    = "flux.${data.terraform_remote_state.base.outputs.zone_name}."
  type    = "AAAA"

  alias {
    name                   = data.terraform_remote_state.elb.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.elb.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_ecs_task_definition" "flux" {
  family                   = "flux"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  tags = {
    Name = "flux"
  }

  container_definitions = jsonencode([{
    name  = "flux",
    image = "miniflux/miniflux:latest",
    depends_on = [{
      "containerName" : "fluxpostgres",
      "condition" : "START"
    }],
    portMappings = [{
      containerPort = 8080,
      hostPort      = 8080
    }],
    environment = [
      {
        name  = "DATABASE_URL",
        value = "postgres://miniflux:${jsondecode(data.aws_secretsmanager_secret_version.fluxdb_password.secret_string)["fluxdb_password"]}@${aws_lb.fluxpostgres_nlb.dns_name}/miniflux?sslmode=disable",
      },
      {
        name  = "RUN_MIGRATIONS",
        value = "1",
      },
      #{
      #  name  = "CREATE_ADMIN",
      #  value = "1",
      #},
      #{
      #  name  = "ADMIN_USERNAME",
      #  value = "FOO",
      #},
      #{
      #  name  = "ADMIN_PASSWORD",
      #  value = "BAR",
      #}
    ],
    "logConfiguration" : {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-group" : "/ecs/containers",
        "awslogs-region" : "eu-central-1",
        "awslogs-stream-prefix" : "flux"
      }
    }
  }])
}

resource "aws_ecs_service" "flux" {
  name                               = "flux"
  cluster                            = aws_ecs_cluster.ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.flux.arn
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  desired_count                      = 1

  tags = {
    Name = "flux"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.flux_tg.arn
    container_name   = "flux" # Must match the name in your container definition
    container_port   = 8080   # The port your container is listening on
  }

  network_configuration {
    subnets = [
      data.terraform_remote_state.base.outputs.public_subnet_a_id,
      data.terraform_remote_state.base.outputs.public_subnet_b_id,
      data.terraform_remote_state.base.outputs.public_subnet_c_id,
    ]
    security_groups  = [data.terraform_remote_state.base.outputs.allow_web_sg_id]
    assign_public_ip = true
  }
}

resource "aws_lb_target_group" "flux_tg" {
  name        = "flux-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id
  target_type = "ip"

  tags = {
    Name = "flux"
  }

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    path                = "/" # Modify if your app has a specific health check path
    protocol            = "HTTP"
    timeout             = 3
    matcher             = "200-499" # miniflux returns method not allowed to the LB check.
  }
}

resource "aws_lb_listener_rule" "flux_https_listener_rule" {
  listener_arn = data.terraform_remote_state.elb.outputs.alb_https_listener_arn
  priority     = 105

  tags = {
    Name = "flux"
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flux_tg.arn
  }

  condition {
    host_header {
      values = ["flux.${data.terraform_remote_state.base.outputs.zone_name}"]
    }
  }
}
