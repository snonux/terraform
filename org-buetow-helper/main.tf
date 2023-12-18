terraform {
  backend "s3" {
    bucket  = "org-buetow-tfstate"
    key     = "org-buetow-helper/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}

provider "aws" {
  region = "eu-central-1" # or your preferred AWS region
}

data "aws_region" "current" {}

data "template_file" "user_data" {
  template = file("${path.module}/user_data.tpl")

  vars = {
    region = data.aws_region.current.name
    efs_id = data.terraform_remote_state.base_remote_state.outputs.my_self_hosted_services_efs_id
  }
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "id_rsa_pub" {
  key_name   = "${var.environment}-id-rsa-pub"
  public_key = file("${path.module}/id_rsa.pub")
}

resource "aws_instance" "my_helper_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.id_rsa_pub.key_name
  subnet_id     = data.terraform_remote_state.base_remote_state.outputs.my_public_subnet_a_id

  vpc_security_group_ids = [
    data.terraform_remote_state.base_remote_state.outputs.allow_ssh_sg_id,
    data.terraform_remote_state.base_remote_state.outputs.allow_web_sg_id,
    data.terraform_remote_state.base_remote_state.outputs.allow_outbound_sg_id,
  ]
  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "${var.environment}-my-helper-instance"
  }
}

data "aws_route53_zone" "my_zone" {
  name = "aws.buetow.org." # Replace with your domain name
}

resource "aws_route53_record" "my_record" {
  zone_id = data.aws_route53_zone.my_zone.zone_id
  name    = "helper.aws.buetow.org" # Replace with your desired subdomain or leave empty for root
  type    = "A"
  ttl     = "300"
  records = [aws_instance.my_helper_instance.public_ip]
}
