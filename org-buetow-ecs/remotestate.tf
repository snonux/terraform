data "terraform_remote_state" "base" {
  backend = "s3"
  config = {
    bucket = "org-buetow-tfstate"
    key    = "org-buetow-base/terraform.tfstate"
    region = "eu-central-1"
  }
}
