data "aws_region" "current" {}

data "template_file" "user_data" {
  template = file("${path.module}/user_data.tpl")

  vars = {
    region = data.aws_region.current.name
    efs_id = data.terraform_remote_state.base.outputs.self_hosted_services_efs_id
  }
}
