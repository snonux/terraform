resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"

  tags = {
    Name = "ecs-cluster"
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
    }]
  })

  tags = {
    Name = "ecs-cluster"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attach_ecr_radicale" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = data.terraform_remote_state.base.outputs.ecr_radicale_read_arn
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attach_ecr_anki_sync_server" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = data.terraform_remote_state.base.outputs.ecr_anki_sync_server_read_arn
}
