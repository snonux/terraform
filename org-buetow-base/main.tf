terraform {
  backend "s3" {
    bucket  = "org-buetow-tfstate"
    key     = "org-buetow-base/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}

provider "aws" {
  region = "eu-central-1" # or your preferred AWS region
}
