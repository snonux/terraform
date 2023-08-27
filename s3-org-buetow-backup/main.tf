terraform {
  backend "s3" {
    bucket = "org-buetow-tfstate"
    key    = "s3-org-buetow-backup/terraform.tfstate"
    region = "eu-central-1"
    # Optional, if you enabled server-side encryption
    encrypt = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "backup_bucket" {
  bucket = "org-buetow-backup"
}

resource "aws_iam_user" "backup_iam_user" {
  name = "org-buetow-backup-user"
}

resource "aws_iam_access_key" "backup_iam_user_key" {
  user = aws_iam_user.backup_iam_user.name
}

resource "aws_iam_user_policy" "backup_iam_user_policy" {
  name = "backup-iam-user-policy"
  user = aws_iam_user.backup_iam_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:RestoreObject",
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.backup_bucket.arn}",
          "${aws_s3_bucket.backup_bucket.arn}/*"
        ]
      }
    ]
  })
}

output "access_key_id" {
  value     = aws_iam_access_key.backup_iam_user_key.id
  sensitive = true
}

output "secret_access_key" {
  value     = aws_iam_access_key.backup_iam_user_key.secret
  sensitive = true
}
