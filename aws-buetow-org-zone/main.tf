terraform {
  backend "s3" {
    bucket = "org-buetow-tfstate"
    key    = "aws-buetow-org-zone/terraform.tfstate"
    region = "eu-central-1"
    # Optional, if you enabled server-side encryption
    encrypt = true
  }
}

provider "aws" {
  region = "eu-central-1" # or your preferred AWS region
}

resource "aws_route53_zone" "my_zone" {
  name = "aws.buetow.org." # Replace with your domain name
}
