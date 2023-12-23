resource "aws_route53_record" "a_record_bag" {
  zone_id = data.terraform_remote_state.base.outputs.buetow_cloud_zone_id
  name    = "bag.buetow.cloud."
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.elb.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.elb.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "aaaa_record_bag" {
  zone_id = data.terraform_remote_state.base.outputs.buetow_cloud_zone_id
  name    = "bag.buetow.cloud."
  type    = "AAAA"

  alias {
    name                   = data.terraform_remote_state.elb.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.elb.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_ecs_task_definition" "bag" {
  family                   = "bag"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  volume {
    name = "bag-db-efs-volume"
    efs_volume_configuration {
      file_system_id = data.terraform_remote_state.base.outputs.self_hosted_services_efs_id
      root_directory = "/ecs/wallabag/data/db"
    }
  }

  volume {
    name = "bag-assets-efs-volume"
    efs_volume_configuration {
      file_system_id = data.terraform_remote_state.base.outputs.self_hosted_services_efs_id
      root_directory = "/ecs/wallabag/data/assets"
    }
  }

  container_definitions = jsonencode([{
    name  = "bag",
    image = "wallabag/wallabag",
    portMappings = [{
      containerPort = 80,
      hostPort      = 80
    }],
    environment = [
      {
        name  = "SYMFONY__ENV__DOMAIN_NAME",
        value = "https://bag.buetow.cloud"
      }
    ],
    mountPoints = [
      {
        sourceVolume  = "bag-db-efs-volume"
        containerPath = "/var/www/bag/data/db"
        readOnly      = false
      },
      {
        sourceVolume  = "bag-assets-efs-volume"
        containerPath = "/var/www/bag/data/assets"
        readOnly      = false
      }
    ],
    "logConfiguration" : {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-group" : "/ecs/containers",
        "awslogs-region" : "eu-central-1",
        "awslogs-stream-prefix" : "bag"
      }
    }
  }])
}

resource "aws_ecs_service" "bag" {
  name            = "bag"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.bag.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.bag_tg.arn
    container_name   = "bag" # Must match the name in your container definition
    container_port   = 80    # The port your container is listening on
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

resource "aws_lb_target_group" "bag_tg" {
  name        = "bag-tg"
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

resource "aws_lb_listener_rule" "bag_https_listener_rule" {
  listener_arn = data.terraform_remote_state.elb.outputs.alb_https_listener_arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bag_tg.arn
  }

  condition {
    host_header {
      values = ["bag.buetow.cloud"]
    }
  }
}
