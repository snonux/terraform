terraform {
  backend "s3" {
    bucket = "org-buetow-tfstate"
    key    = "playground/fargate/terraform.tfstate"
    region = "eu-central-1"
    # Optional, if you enabled server-side encryption
    encrypt = true
  }
}

provider "aws" {
  region = "eu-central-1" # or your preferred AWS region
}

