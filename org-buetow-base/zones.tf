data "aws_route53_zone" "buetow_cloud" {
  name         = "buetow.cloud."
  private_zone = false
}

resource "aws_route53_zone" "buetow_private" {
  name = "buetow.private"

  vpc {
    vpc_id = aws_vpc.vpc.id
  }
}
