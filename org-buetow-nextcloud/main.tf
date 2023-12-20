terraform {
  backend "s3" {
    bucket  = "org-buetow-tfstate"
    key     = "org-buetow-nextcloud/terraform.tfstate"
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
    efs_id = data.terraform_remote_state.base.outputs.self_hosted_services_efs_id
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
  key_name   = "nextcloud-id-rsa-pub"
  public_key = file("${path.module}/id_rsa.pub")
}

resource "aws_instance" "nextcloud" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.medium"
  key_name      = aws_key_pair.id_rsa_pub.key_name
  subnet_id     = data.terraform_remote_state.base.outputs.public_subnet_a_id

  vpc_security_group_ids = [
    data.terraform_remote_state.base.outputs.allow_ssh_sg_id,
    data.terraform_remote_state.base.outputs.allow_web_sg_id,
    data.terraform_remote_state.base.outputs.allow_outbound_sg_id,
  ]
  user_data = data.template_file.user_data.rendered
}

resource "aws_route53_record" "nextcloud_ec2_aws_buetow_org" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "nextcloud-ec2.aws.buetow.org" # Replace with your desired subdomain or leave empty for root
  type    = "A"
  ttl     = "300"
  records = [aws_instance.nextcloud.public_ip]
}
