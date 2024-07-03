data "terraform_remote_state" "base" {
  backend = "s3"
  config = {
    bucket = "org-buetow-tfstate"
    key    = "org-buetow-base/terraform.tfstate"
    region = "eu-central-1"
  }
}

data "terraform_remote_state" "elb" {
  backend = "s3"
  config = {
    bucket = "org-buetow-tfstate"
    key    = "org-buetow-elb/terraform.tfstate"
    region = "eu-central-1"
  }
}
