data "aws_iam_policy_document" "efs_csi_policy" {
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:DescribeFileSystems"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:CreateAccessPoint",
      "elasticfilesystem:DeleteAccessPoint",
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeMountTargets"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "efs_csi_policy" {
  name        = "AmazonEKS_EFS_CSI_DriverPolicy"
  description = "Policy for EFS CSI Driver"
  policy      = data.aws_iam_policy_document.efs_csi_policy.json
}

resource "aws_iam_role" "efs_csi_role" {
  name = "AmazonEKS_EFS_CSI_DriverRole"

  assume_role_policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Effect : "Allow"
        Principal : {
          Service : "eks.amazonaws.com"
        }
        Action : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "efs_csi_role_policy_attachment" {
  role       = aws_iam_role.efs_csi_role.name
  policy_arn = aws_iam_policy.efs_csi_policy.arn
}

resource "aws_eks_addon" "efs_csi_addon" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-efs-csi-driver"
  addon_version            = "v2.0.4-eksbuild.1" # You can specify exact version if needed.
  service_account_role_arn = aws_iam_role.efs_csi_role.arn

  depends_on = [
    # Ensure the add-on is installed after the role is c reated
    aws_iam_role_policy_attachment.efs_csi_role_policy_attachment
  ]
}


