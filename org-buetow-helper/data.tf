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
