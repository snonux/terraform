terraform {
  backend "s3" {
    bucket  = "org-buetow-tfstate"
    key     = "org-buetow-eks/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

