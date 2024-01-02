resource "aws_lb" "syncthing_nlb" {
  count              = var.deploy_syncthing ? 1 : 0
  name               = "syncthing-nlb"
  internal           = false
  load_balancer_type = "network"
  ip_address_type    = "dualstack"
  security_groups = [
    aws_security_group.syncthing[0].id,
  ]
  subnets = [
    data.terraform_remote_state.base.outputs.public_subnet_a_id,
    data.terraform_remote_state.base.outputs.public_subnet_b_id,
    data.terraform_remote_state.base.outputs.public_subnet_c_id,
  ]

  tags = {
    Name = "syncthing"
  }
}

resource "aws_lb_listener" "syncthing_data_tcp" {
  count             = var.deploy_syncthing ? 1 : 0
  load_balancer_arn = aws_lb.syncthing_nlb[0].arn
  protocol          = "TCP"
  port              = 22000

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.syncthing_data_tcp[0].arn
  }

  tags = {
    Name = "syncthing"
  }
}

resource "aws_lb_target_group" "syncthing_data_tcp" {
  count       = var.deploy_syncthing ? 1 : 0
  name        = "syncthing-data-tcp"
  port        = 22000
  protocol    = "TCP"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id
  target_type = "ip"

  tags = {
    Name = "syncthing"
  }
}

resource "aws_route53_record" "a_record_syncthing" {
  count   = var.deploy_syncthing ? 1 : 0
  zone_id = data.terraform_remote_state.base.outputs.zone_id
  name    = "syncthing.${data.terraform_remote_state.base.outputs.zone_name}."
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.elb.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.elb.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "aaaa_record_syncthing" {
  count   = var.deploy_syncthing ? 1 : 0
  zone_id = data.terraform_remote_state.base.outputs.zone_id
  name    = "syncthing.${data.terraform_remote_state.base.outputs.zone_name}."
  type    = "AAAA"

  alias {
    name                   = data.terraform_remote_state.elb.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.elb.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb_target_group" "syncthing_ui_tg" {
  count       = var.deploy_syncthing ? 1 : 0
  name        = "syncthing-ui-tg"
  port        = 8384
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id
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

  tags = {
    Name = "syncthing"
  }
}

resource "aws_lb_listener_rule" "syncthing_ui_https_listener_rule" {
  count        = var.deploy_syncthing ? 1 : 0
  listener_arn = data.terraform_remote_state.elb.outputs.alb_https_listener_arn
  priority     = 104

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.syncthing_ui_tg[0].arn
  }

  condition {
    host_header {
      values = ["syncthing.${data.terraform_remote_state.base.outputs.zone_name}"]
    }
  }

  tags = {
    Name = "syncthing"
  }
}


resource "aws_route53_record" "a_record_syncthing_data" {
  count   = var.deploy_syncthing ? 1 : 0
  zone_id = data.terraform_remote_state.base.outputs.zone_id
  name    = "syncthing-data.${data.terraform_remote_state.base.outputs.zone_name}."
  type    = "A"

  alias {
    name                   = aws_lb.syncthing_nlb[0].dns_name
    zone_id                = aws_lb.syncthing_nlb[0].zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "aaaa_record_syncthing_data" {
  count   = var.deploy_syncthing ? 1 : 0
  zone_id = data.terraform_remote_state.base.outputs.zone_id
  name    = "syncthing-data.${data.terraform_remote_state.base.outputs.zone_name}."
  type    = "AAAA"

  alias {
    name                   = aws_lb.syncthing_nlb[0].dns_name
    zone_id                = aws_lb.syncthing_nlb[0].zone_id
    evaluate_target_health = true
  }
}

resource "aws_ecs_task_definition" "syncthing" {
  count                    = var.deploy_syncthing ? 1 : 0
  family                   = "syncthing"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  tags = {
    Name = "syncthing"
  }

  volume {
    name = "syncthing-config-efs-volume"
    efs_volume_configuration {
      file_system_id = data.terraform_remote_state.base.outputs.self_hosted_services_efs_id
      root_directory = "/ecs/syncthing/config"
    }
  }

  volume {
    name = "syncthing-data1-efs-volume"
    efs_volume_configuration {
      file_system_id = data.terraform_remote_state.base.outputs.self_hosted_services_efs_id
      root_directory = "/ecs/syncthing/data1"
    }
  }

  volume {
    name = "syncthing-data2-efs-volume"
    efs_volume_configuration {
      file_system_id = data.terraform_remote_state.base.outputs.self_hosted_services_efs_id
      root_directory = "/ecs/syncthing/data2"
    }
  }

  container_definitions = jsonencode([{
    name  = "syncthing",
    image = "lscr.io/linuxserver/syncthing:latest",
    portMappings = [
      {
        containerPort = 8384,
        hostPort      = 8384,
        protocol      = "tcp"
      },
      {
        containerPort = 22000,
        hostPort      = 22000,
        protocol      = "tcp"
      }
    ],
    mountPoints = [
      {
        sourceVolume  = "syncthing-config-efs-volume"
        containerPath = "/config"
        readOnly      = false
      },
      {
        sourceVolume  = "syncthing-data1-efs-volume"
        containerPath = "/data1"
        readOnly      = false
      },
      {
        sourceVolume  = "syncthing-data2-efs-volume"
        containerPath = "/data2",
        readOnly      = false
      }
    ],
    "logConfiguration" : {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-group" : "/ecs/containers",
        "awslogs-region" : "eu-central-1",
        "awslogs-stream-prefix" : "syncthing"
      }
    }
  }])
}

resource "aws_security_group" "syncthing" {
  count       = var.deploy_syncthing ? 1 : 0
  name        = "allow-syncthing"
  description = "Allow traffic on syncthing ports"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id

  ingress {
    description      = "Allow inbound TCP traffic on port 8384"
    from_port        = 8384
    to_port          = 8384
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allow inbound TCP traffic on port 22000"
    from_port        = 22000
    to_port          = 22000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  #ingress {
  #  description      = "Allow inbound UDP traffic on port 22000"
  #  from_port        = 22000
  #  to_port          = 22000
  #  protocol         = "udp"
  #  cidr_blocks      = ["0.0.0.0/0"]
  #  ipv6_cidr_blocks = ["::/0"]
  #}

  #ingress {
  #  description      = "Allow inbound UDP traffic on port 21027"
  #  from_port        = 21027
  #  to_port          = 21027
  #  protocol         = "udp"
  #  cidr_blocks      = ["0.0.0.0/0"]
  #  ipv6_cidr_blocks = ["::/0"]
  #}

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" # Allows all outbound traffic
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "syncthing"
  }
}

resource "aws_ecs_service" "syncthing" {
  count                              = var.deploy_syncthing ? 1 : 0
  name                               = "syncthing"
  cluster                            = aws_ecs_cluster.ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.syncthing[0].arn
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  desired_count                      = 1

  tags = {
    Name = "syncthing"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.syncthing_ui_tg[0].arn
    container_name   = "syncthing" # Must match the name in your container definition
    container_port   = 8384        # The port your container is listening on
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.syncthing_data_tcp[0].arn
    container_name   = "syncthing" # Must match the name in your container definition
    container_port   = 22000       # The port your container is listening on
  }

  network_configuration {
    subnets = [
      data.terraform_remote_state.base.outputs.public_subnet_a_id,
      data.terraform_remote_state.base.outputs.public_subnet_b_id,
      data.terraform_remote_state.base.outputs.public_subnet_c_id,
    ]
    security_groups  = [aws_security_group.syncthing[0].id]
    assign_public_ip = true
  }
}
