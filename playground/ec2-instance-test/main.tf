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
  key_name   = "${var.environment}-ec2_instance_test_paul@earth"
  public_key = file("${path.module}/id_rsa.pub")
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
  instance_type = "t2.micro"
  key_name      = aws_key_pair.id_rsa_pub.key_name
  subnet_id     = aws_subnet.my_public_subnet.id

  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_http.id,
    aws_security_group.allow_https.id,
    aws_security_group.allow_outbound.id
  ]
  user_data  = data.template_file.user_data.rendered
  depends_on = [aws_efs_file_system.my_efs]

  tags = {
    Name = "${var.environment}-ec2-instance"
  }
}

data "aws_route53_zone" "my_zone" {
  name = "aws.buetow.org." # Replace with your domain name
}

resource "aws_route53_record" "my_record" {
  zone_id = data.aws_route53_zone.my_zone.zone_id
  name    = "${var.environment}-ec2-instance.aws.buetow.org" # Replace with your desired subdomain or leave empty for root
  type    = "A"
  ttl     = "300"
  records = [aws_instance.my_instance.public_ip]
}
