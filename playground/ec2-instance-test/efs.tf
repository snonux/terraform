resource "aws_efs_file_system" "my_efs" {
  creation_token = "my-efs"
  encrypted      = true

  tags = {
    Name = "MyEFS"
  }
}

resource "aws_efs_mount_target" "efs_mt" {
  file_system_id  = aws_efs_file_system.my_efs.id
  subnet_id       = aws_subnet.my_public_subnet.id # Replace with your subnet ID
  security_groups = [aws_security_group.efs_sg.id] # Replace with your security group ID
}

resource "aws_security_group" "efs_sg" {
  vpc_id = aws_vpc.my_vpc.id # Replace with your VPC ID

  ingress {
    from_port   = 2049 # NFS port
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Replace with the CIDR block of your VPC or EC2 instance subnet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "efs-sg"
  }
}
