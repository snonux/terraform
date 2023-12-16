terraform {
  backend "s3" {
    bucket = "org-buetow-tfstate"
    key    = "playground/ec2-instance-test/terraform.tfstate"
    region = "eu-central-1"
    # Optional, if you enabled server-side encryption
    encrypt = true
  }
}

provider "aws" {
  region = "eu-central-1" # or your preferred AWS region
}

data "aws_region" "current" {}

resource "aws_key_pair" "id_rsa_pub" {
  key_name   = "ec2_instance_test_paul@earth"
  public_key = file("${path.module}/id_rsa.pub")
}


resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16" # Specify your CIDR block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}

resource "aws_subnet" "my_public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id # Referencing the VPC
  cidr_block              = "10.0.1.0/24"     # Specify your CIDR block for the subnet
  availability_zone       = "eu-central-1a"   # Change to your desired AZ
  map_public_ip_on_launch = true

  tags = {
    Name = "my-subnet"
  }
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "my-route-table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my_public_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_https" {
  name        = "allow_https"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_outbound" {
  name        = "allow_outbound"
  description = "Allow outbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"] # Allows outbound traffic to all IP addresses
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user_data.tpl")

  vars = {
    region = data.aws_region.current.name
    efs_id = aws_efs_file_system.my_efs.id
  }
}

resource "aws_instance" "my_instance" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.large"
  key_name      = aws_key_pair.id_rsa_pub.key_name
  subnet_id     = aws_subnet.my_public_subnet.id
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_http.id,
    aws_security_group.allow_https.id,
    aws_security_group.allow_outbound.id
  ]
  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "my-instance"
  }
}

resource "aws_route53_zone" "my_zone" {
  name = "aws.buetow.org." # Replace with your domain name
}

resource "aws_route53_record" "my_record" {
  zone_id = aws_route53_zone.my_zone.zone_id
  name    = "ec2-instance-test.aws.buetow.org" # Replace with your desired subdomain or leave empty for root
  type    = "A"
  ttl     = "300"
  records = [aws_instance.my_instance.public_ip]
}
