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

resource "aws_key_pair" "id_rsa_pub" {
  key_name   = "ec2_instance_test_paul@earth"
  public_key = file("${path.module}/id_rsa.pub")
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "my_instance" {
  ami             = "ami-0059170a80e36d30f" # FreeBSD
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.id_rsa_pub.key_name
  security_groups = [aws_security_group.allow_ssh.name]

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
