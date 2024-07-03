output "cluster_id" {
  value = aws_eks_cluster.org_buetow_eks.id
}

output "cluster_endpoint" {
  value = aws_eks_cluster.org_buetow_eks.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.org_buetow_eks.certificate_authority.0.data
}

output "update_kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${aws_eks_cluster.org_buetow_eks.name} --region eu-central-1"
}
