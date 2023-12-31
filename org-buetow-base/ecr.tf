# Radicale Docker image from https://codeberg.org/snonux/docker-radicale-server
resource "aws_ecr_repository" "readicale" {
  name = "radicale"

  tags = {
    Name = "radicale"
  }
}

resource "aws_iam_policy" "ecr_radicale_read" {
  name        = "ecr-radicale-read"
  description = "Allow ECS tasks to pull from ECR"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ],
        Resource = "arn:aws:ecr:eu-central-1:634617747016:repository/radicale"
      },
      {
        Effect   = "Allow",
        Action   = "ecr:GetAuthorizationToken",
        Resource = "*"
      }
    ]
  })
}
