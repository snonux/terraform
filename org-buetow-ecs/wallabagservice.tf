resource "aws_route53_record" "a_record_wallabag" {
  zone_id = data.terraform_remote_state.base.outputs.aws_buetow_org_zone_id
  name    = "wallabag.aws.buetow.org."
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.elb.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.elb.outputs.alb_zone_id
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
  #task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  volume {
    name = "wallabag-db-efs-volume"
    efs_volume_configuration {
      file_system_id = data.terraform_remote_state.base.outputs.self_hosted_services_efs_id
      root_directory = "/ecs/wallabag/data/db"
    }
  }

  volume {
    name = "wallabag-assets-efs-volume"
    efs_volume_configuration {
      file_system_id = data.terraform_remote_state.base.outputs.self_hosted_services_efs_id
      root_directory = "/ecs/wallabag/data/assets"
    }
  }

  container_definitions = jsonencode([{
    name  = "wallabag",
    image = "wallabag/wallabag",
    #entryPoint = ["/bin/sh", "-c"],
    #command    = ["ls", "-ld", "/var/www/wallabag/*"],
    portMappings = [{
      containerPort = 80,
      hostPort      = 80
    }],
    environment = [
      {
        name  = "SYMFONY__ENV__DOMAIN_NAME",
        value = "https://wallabag.aws.buetow.org"
      }
    ],
    mountPoints = [
      {
        sourceVolume  = "wallabag-db-efs-volume"
        containerPath = "/var/www/wallabag/data/db"
        readOnly      = false
      },
      {
        sourceVolume  = "wallabag-assets-efs-volume"
        containerPath = "/var/www/wallabag/data/assets"
        readOnly      = false
      }
    ],
    "logConfiguration" : {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-group" : "/ecs/containers",
        "awslogs-region" : "eu-central-1",
        "awslogs-stream-prefix" : "wallabag"
      }
    }
  }])
}

resource "aws_ecs_service" "wallabag_service" {
  name            = "wallabag"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.wallabag_task.arn
  launch_type     = "FARGATE"
  desired_count   = 0

  load_balancer {
    target_group_arn = aws_lb_target_group.wallabag_tg.arn
    container_name   = "wallabag" # Must match the name in your container definition
    container_port   = 80         # The port your container is listening on
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

resource "aws_lb_target_group" "wallabag_tg" {
  name        = "wallabag-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    path                = "/login" # Modify if your app has a specific health check path
    protocol            = "HTTP"
    timeout             = 3
    matcher             = "200-299"
  }
}

resource "aws_lb_listener_rule" "wallabag_https_listener_rule" {
  listener_arn = data.terraform_remote_state.elb.outputs.alb_https_listener_arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wallabag_tg.arn
  }

  condition {
    host_header {
      values = ["wallabag.aws.buetow.org"]
    }
  }
}
