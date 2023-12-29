resource "aws_route53_record" "a_record_vault" {
  zone_id = data.terraform_remote_state.base.outputs.buetow_cloud_zone_id
  name    = "vault.buetow.cloud."
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.elb.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.elb.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "aaaa_record_vault" {
  zone_id = data.terraform_remote_state.base.outputs.buetow_cloud_zone_id
  name    = "vault.buetow.cloud."
  type    = "AAAA"

  alias {
    name                   = data.terraform_remote_state.elb.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.elb.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_ecs_task_definition" "vault" {
  family                   = "vault"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  tags = {
    Name = "vault-task"
  }

  volume {
    name = "vault-data-efs-volume"
    efs_volume_configuration {
      file_system_id = data.terraform_remote_state.base.outputs.self_hosted_services_efs_id
      root_directory = "/ecs/vault/data"
    }
  }

  container_definitions = jsonencode([{
    name  = "vault",
    image = "vaultwarden/server:latest",
    portMappings = [{
      containerPort = 80,
      hostPort      = 80
    }],
    mountPoints = [
      {
        sourceVolume  = "vault-data-efs-volume"
        containerPath = "/data"
        readOnly      = false
      }
    ],
    "logConfiguration" : {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-group" : "/ecs/containers",
        "awslogs-region" : "eu-central-1",
        "awslogs-stream-prefix" : "vault"
      }
    }
  }])
}

resource "aws_ecs_service" "vault" {
  name                               = "vault"
  cluster                            = aws_ecs_cluster.ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.vault.arn
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  desired_count                      = 0

  tags = {
    Name = "vault-service"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.vault_tg.arn
    container_name   = "vault" # Must match the name in your container definition
    container_port   = 80      # The port your container is listening on
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

resource "aws_lb_target_group" "vault_tg" {
  name        = "vault-tg"
  port        = 80
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
}

resource "aws_lb_listener_rule" "vault_https_listener_rule" {
  listener_arn = data.terraform_remote_state.elb.outputs.alb_https_listener_arn
  priority     = 103

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault_tg.arn
  }

  condition {
    host_header {
      values = ["vault.buetow.cloud"]
    }
  }
}
