terraform {
  backend "s3" {
    bucket  = "org-buetow-tfstate"
    key     = "playground/ec2-eks-test/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}

provider "aws" {
  region = "eu-central-1" # or your preferred AWS region
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block         = "10.0.0.0/16"
  enable_dns_support = true

  tags = {
    Name      = "my_vpc"
    Terraform = "true"
  }
}

# Create a Public Subnet
resource "aws_subnet" "my_public_subnet" {
  count      = 3
  cidr_block = "10.0.${count.index + 1}.0/24"
  vpc_id     = aws_vpc.my_vpc.id

  map_public_ip_on_launch = true

  tags = {
    Name      = "my_public_subnet-${count.index}"
    Terraform = "true"
  }
}

# Create a Private Subnet
resource "aws_subnet" "my_private_subnet" {
  count      = 3
  cidr_block = "10.0.${count.index + 4}.0/24"
  vpc_id     = aws_vpc.my_vpc.id

  tags = {
    Name      = "my_private_subnet-${count.index}"
    Terraform = "true"
  }
}

# EKS Cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-cluster"
  cluster_version = "1.21"
  subnets         = aws_subnet.my_private_subnet[*].id
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

  vpc_id = aws_vpc.my_vpc.id

  node_groups = {
    eks_nodes = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_type = "t3.small"
      key_name      = var.key_name
      subnets       = aws_subnet.my_private_subnet[*].id

      tags = {
        Terraform   = "true"
        Environment = "dev"
      }
    }
  }
}
