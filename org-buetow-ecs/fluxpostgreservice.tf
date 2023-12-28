resource "aws_lb" "fluxpostgres_nlb" {
  name               = "fluxpostgres-nlb"
  internal           = true
  load_balancer_type = "network"
  ip_address_type    = "dualstack"
  security_groups = [
    aws_security_group.fluxpostgres.id,
  ]
  subnets = [
    data.terraform_remote_state.base.outputs.public_subnet_a_id,
    data.terraform_remote_state.base.outputs.public_subnet_b_id,
    data.terraform_remote_state.base.outputs.public_subnet_c_id,
  ]
}

#output "fluxpostgres_dns_name" {
#  value = aws_lb.fluxpostgres_nlb.dns_name
#}

resource "aws_lb_listener" "fluxpostgres_tcp" {
  load_balancer_arn = aws_lb.fluxpostgres_nlb.arn
  protocol          = "TCP"
  port              = 5432

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fluxpostgres_tcp.arn
  }
}

resource "aws_lb_target_group" "fluxpostgres_tcp" {
  name        = "fluxpostgres-tcp"
  port        = 5432
  protocol    = "TCP"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id
  target_type = "ip"
}

#resource "aws_route53_record" "a_record_fluxpostgres" {
#  zone_id = data.terraform_remote_state.base.outputs.buetow_internal_zone_id
#  name    = "fluxpostgres.buetow.internal."
#  type    = "A"
#
#  alias {
#    name                   = aws_lb.fluxpostgres_nlb.dns_name
#    zone_id                = aws_lb.fluxpostgres_nlb.zone_id
#    evaluate_target_health = true
#  }
#}

#resource "aws_route53_record" "aaaa_record_fluxpostgres" {
#  zone_id = data.terraform_remote_state.base.outputs.buetow_internal_zone_id
#  name    = "fluxpostgres.buetow.internal."
#  type    = "AAAA"
#
#  alias {
#    name                   = aws_lb.fluxpostgres_nlb.dns_name
#    zone_id                = aws_lb.fluxpostgres_nlb.zone_id
#    evaluate_target_health = true
#  }
#}

resource "aws_ecs_task_definition" "fluxpostgres" {
  family                   = "fluxpostgres"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  volume {
    name = "fluxpostgres-efs-volume"
    efs_volume_configuration {
      file_system_id = data.terraform_remote_state.base.outputs.self_hosted_services_efs_id
      root_directory = "/ecs/fluxpostgres/"
    }
  }

  container_definitions = jsonencode([{
    name  = "fluxpostgres",
    image = "postgres:15",
    portMappings = [
      {
        containerPort = 5432,
        hostPort      = 5432,
        protocol      = "tcp"
      }
    ],
    environment = [
      {
        name  = "POSTGRES_USER",
        value = "miniflux"
      },
      {
        name  = "POSTGRES_PASSWORD",
        value = var.fluxdb_password,
      }
    ],
    mountPoints = [
      {
        sourceVolume  = "fluxpostgres-efs-volume"
        containerPath = "/var/lib/postgresql/data"
        readOnly      = false
      }
    ],
    #"logConfiguration" : {
    #  "logDriver" : "awslogs",
    #  "options" : {
    #    "awslogs-group" : "/ecs/containers",
    #    "awslogs-region" : "eu-central-1",
    #    "awslogs-stream-prefix" : "fluxpostgres"
    #  }
    #}
  }])
}

resource "aws_security_group" "fluxpostgres" {
  name        = "allow-fluxpostgres"
  description = "Allow traffic on fluxpostgres ports"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id

  ingress {
    description      = "Allow inbound TCP traffic on fluxpostgresQL port"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allow inbound UDP traffic on fluxpostgresQL port"
    from_port        = 5432
    to_port          = 5432
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # TODO: Required? Yes for contianer pull
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" # Allows all outbound traffic
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow-fluxpostgres"
  }
}
resource "aws_ecs_service" "fluxpostgres" {
  name                               = "fluxpostgres"
  cluster                            = aws_ecs_cluster.ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.fluxpostgres.arn
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  desired_count                      = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.fluxpostgres_tcp.arn
    container_name   = "fluxpostgres"
    container_port   = 5432
  }

  network_configuration {
    subnets = [
      data.terraform_remote_state.base.outputs.public_subnet_a_id,
      data.terraform_remote_state.base.outputs.public_subnet_b_id,
      data.terraform_remote_state.base.outputs.public_subnet_c_id,
    ]
    security_groups  = [aws_security_group.fluxpostgres.id]
    assign_public_ip = false
  }
}
