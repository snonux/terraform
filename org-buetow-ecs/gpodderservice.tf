resource "aws_route53_record" "a_record_gpodder" {
  count   = var.deploy_gpodder ? 1 : 0
  zone_id = data.terraform_remote_state.base.outputs.zone_id
  name    = "gpodder.${data.terraform_remote_state.base.outputs.zone_name}."
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.elb.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.elb.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "aaaa_record_gpodder" {
  count   = var.deploy_gpodder ? 1 : 0
  zone_id = data.terraform_remote_state.base.outputs.zone_id
  name    = "gpodder.${data.terraform_remote_state.base.outputs.zone_name}."
  type    = "AAAA"

  alias {
    name                   = data.terraform_remote_state.elb.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.elb.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_ecs_task_definition" "gpodder" {
  count                    = var.deploy_gpodder ? 1 : 0
  family                   = "gpodder"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  tags = {
    Name = "gpodder"
  }

  volume {
    name = "gpodder-data-efs-volume"
    efs_volume_configuration {
      file_system_id = data.terraform_remote_state.base.outputs.self_hosted_services_efs_id
      root_directory = "/ecs/gpodder/data"
    }
  }

  container_definitions = jsonencode([{
    name  = "gpodder",
    image = "634617747016.dkr.ecr.eu-central-1.amazonaws.com/micro-gpodder-server:latest",
    portMappings = [{
      containerPort = 8080,
      hostPort      = 8080
    }],
    mountPoints = [
      {
        sourceVolume  = "gpodder-data-efs-volume"
        containerPath = "/var/www/server/data"
        readOnly      = false
      }
    ],
    "logConfiguration" : {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-group" : "/ecs/containers",
        "awslogs-region" : "eu-central-1",
        "awslogs-stream-prefix" : "gpodder"
      }
    }
  }])
}

resource "aws_ecs_service" "gpodder" {
  count                              = var.deploy_gpodder ? 1 : 0
  name                               = "gpodder"
  cluster                            = aws_ecs_cluster.ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.gpodder[0].arn
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  desired_count                      = 1

  tags = {
    Name = "gpodder"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.gpodder_tg[0].arn
    container_name   = "gpodder" # Must match the name in your container definition
    container_port   = 8080      # The port your container is listening on
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

resource "aws_lb_target_group" "gpodder_tg" {
  count       = var.deploy_gpodder ? 1 : 0
  name        = "gpodder-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 3
    matcher             = "200-299"
  }

  tags = {
    Name = "gpodder"
  }
}

resource "aws_lb_listener_rule" "gpodder_https_listener_rule" {
  count        = var.deploy_gpodder ? 1 : 0
  listener_arn = data.terraform_remote_state.elb.outputs.alb_https_listener_arn
  priority     = 107

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gpodder_tg[0].arn
  }

  condition {
    host_header {
      values = ["gpodder.${data.terraform_remote_state.base.outputs.zone_name}"]
    }
  }

  tags = {
    Name = "gpodder"
  }
}
