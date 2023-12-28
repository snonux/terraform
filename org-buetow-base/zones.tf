data "aws_route53_zone" "buetow_cloud" {
  name         = "buetow.cloud."
  private_zone = false
}

#resource "aws_route53_zone" "buetow_internal" {
#  name = "buetow.internal"
#
#  vpc {
#    vpc_id = aws_vpc.vpc.id
#  }
#}
