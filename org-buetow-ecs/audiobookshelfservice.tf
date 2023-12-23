resource "aws_route53_record" "a_record_audiobookshelf" {
  zone_id = data.terraform_remote_state.base.outputs.buetow_cloud_zone_id
  name    = "audiobookshelf.buetow.cloud."
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.elb.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.elb.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "aaaa_record_audiobookshelf" {
  zone_id = data.terraform_remote_state.base.outputs.buetow_cloud_zone_id
  name    = "audiobookshelf.buetow.cloud."
  type    = "AAAA"

  alias {
    name                   = data.terraform_remote_state.elb.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.elb.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_ecs_task_definition" "audiobookshelf" {
  family                   = "audiobookshelf"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  volume {
    name = "audiobookshelf-config-efs-volume"
    efs_volume_configuration {
      file_system_id = data.terraform_remote_state.base.outputs.self_hosted_services_efs_id
      root_directory = "/ecs/audiobookshelf/config"
    }
  }

  volume {
    name = "audiobookshelf-metadata-efs-volume"
    efs_volume_configuration {
      file_system_id = data.terraform_remote_state.base.outputs.self_hosted_services_efs_id
      root_directory = "/ecs/audiobookshelf/metadata"
    }
  }

  volume {
    name = "audiobookshelf-audiobooks-efs-volume"
    efs_volume_configuration {
      file_system_id = data.terraform_remote_state.base.outputs.self_hosted_services_efs_id
      root_directory = "/ecs/audiobookshelf/audiobooks"
    }
  }

  volume {
    name = "audiobookshelf-podcasts-efs-volume"
    efs_volume_configuration {
      file_system_id = data.terraform_remote_state.base.outputs.self_hosted_services_efs_id
      root_directory = "/ecs/audiobookshelf/podcasts"
    }
  }

  container_definitions = jsonencode([{
    name  = "audiobookshelf",
    image = "ghcr.io/advplyr/audiobookshelf"
    portMappings = [{
      containerPort = 80,
      hostPort      = 80
    }],
    mountPoints = [
      {
        sourceVolume  = "audiobookshelf-config-efs-volume"
        containerPath = "/config"
        readOnly      = false
      },
      {
        sourceVolume  = "audiobookshelf-metadata-efs-volume"
        containerPath = "/metadata"
        readOnly      = false
      },
      {
        sourceVolume  = "audiobookshelf-audiobooks-efs-volume"
        containerPath = "/audiobooks"
        readOnly      = false
      },
      {
        sourceVolume  = "audiobookshelf-podcasts-efs-volume"
        containerPath = "/podcasts"
        readOnly      = false
      },
    ],
    "logConfiguration" : {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-group" : "/ecs/containers",
        "awslogs-region" : "eu-central-1",
        "awslogs-stream-prefix" : "audiobookshelf"
      }
    }
  }])
}

resource "aws_ecs_service" "audiobookshelf" {
  name            = "audiobookshelf"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.audiobookshelf.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.audiobookshelf_tg.arn
    container_name   = "audiobookshelf" # Must match the name in your container definition
    container_port   = 80               # The port your container is listening on
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

resource "aws_lb_target_group" "audiobookshelf_tg" {
  name        = "audiobookshelf-tg"
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

resource "aws_lb_listener_rule" "audiobookshelf_https_listener_rule" {
  listener_arn = data.terraform_remote_state.elb.outputs.alb_https_listener_arn
  priority     = 102

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.audiobookshelf_tg.arn
  }

  condition {
    host_header {
      values = ["audiobookshelf.buetow.cloud"]
    }
  }
}
