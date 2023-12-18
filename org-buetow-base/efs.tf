resource "aws_efs_file_system" "my_self_hosted_services_efs" {
  creation_token = "my-self-hosted-services-efs"
  encrypted      = true

  tags = {
    Name = "${var.environment}-my-self-hosted-services-efs"
  }
}

resource "aws_efs_mount_target" "efs_mt_a" {
  file_system_id  = aws_efs_file_system.my_self_hosted_services_efs.id
  subnet_id       = aws_subnet.my_public_subnet_a.id
  security_groups = [aws_security_group.efs_self_hosted_services_sg.id]
}

resource "aws_efs_mount_target" "efs_mt_b" {
  file_system_id  = aws_efs_file_system.my_self_hosted_services_efs.id
  subnet_id       = aws_subnet.my_public_subnet_b.id
  security_groups = [aws_security_group.efs_self_hosted_services_sg.id]
}

resource "aws_efs_mount_target" "efs_mt_c" {
  file_system_id  = aws_efs_file_system.my_self_hosted_services_efs.id
  subnet_id       = aws_subnet.my_public_subnet_c.id
  security_groups = [aws_security_group.efs_self_hosted_services_sg.id]
}

resource "aws_security_group" "efs_self_hosted_services_sg" {
  vpc_id = aws_vpc.my_vpc.id # Replace with your VPC ID

  ingress {
    from_port   = 2049 # NFS port
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "efs-sg"
    Name = "${var.environment}-efs-sg"
  }
}
