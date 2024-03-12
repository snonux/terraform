data "aws_route53_zone" "cool_buetow_org" {
  name         = "cool.buetow.org."
  private_zone = false
}
