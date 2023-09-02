terraform {
  backend "s3" {
    bucket  = "org-buetow-tfstate"
    key     = "eu-central-1-vpc/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}

provider "aws" {
  region = "eu-central-1" # or your preferred AWS region
}

# Create a new VPC
resource "aws_vpc" "org_buetow_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "org_buetow_vpc"
  }
}

# Fetch availability zones
data "aws_availability_zones" "available" {
}

# Create three subnets, one for each availability zone
resource "aws_subnet" "eks_control_pane_subnets" {
  count = 3

  cidr_block        = "10.0.${count.index + 10}.0/24"
  vpc_id            = aws_vpc.org_buetow_vpc.id
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "eks_control_pane_subnet-${count.index}"
  }
}

# Create three subnets, one for each availability zone
resource "aws_subnet" "eks_subnets" {
  count = 3

  cidr_block        = "10.0.${count.index + 1}.0/24"
  vpc_id            = aws_vpc.org_buetow_vpc.id
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "eks_subnet-${count.index}"
  }
}

output "eks_control_pane_subnet_ids" {
  value       = aws_subnet.eks_control_pane_subnets[*].id
  description = "The IDs of the EKS control pane subnets"
}

output "eks_subnet_ids" {
  value       = aws_subnet.eks_subnets[*].id
  description = "The IDs of the EKS subnets"
}
