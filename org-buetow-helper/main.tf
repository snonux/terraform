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

resource "aws_key_pair" "id_rsa_pub" {
  key_name   = "bastion-id-rsa-pub"
  public_key = file("${path.module}/id_rsa.pub")
}

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.id_rsa_pub.key_name
  subnet_id     = data.terraform_remote_state.base.outputs.public_subnet_b_id

  vpc_security_group_ids = [
    data.terraform_remote_state.base.outputs.allow_ssh_sg_id,
    data.terraform_remote_state.base.outputs.allow_web_sg_id,
    data.terraform_remote_state.base.outputs.allow_outbound_sg_id,
  ]
  user_data = data.template_file.user_data.rendered
}

resource "aws_route53_record" "bastion_buetow_cloud" {
  zone_id = data.terraform_remote_state.base.outputs.buetow_cloud_zone_id
  name    = "bastion.buetow.cloud"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.bastion.public_ip]
}
