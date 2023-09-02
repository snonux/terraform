output "vpc_id" {
  value       = aws_vpc.org_buetow_vpc.id
  description = "The IDs of the VPC"
}

output "eks_control_pane_subnet_ids" {
  value       = aws_subnet.eks_control_pane_subnets[*].id
  description = "The IDs of the EKS control pane subnets"
}

output "eks_subnet_ids" {
  value       = aws_subnet.eks_subnets[*].id
  description = "The IDs of the EKS subnets"
}

output "security_group_id" {
  value       = aws_security_group.org_buetow_sg.id
  description = "The IDs of the created security group"
}
