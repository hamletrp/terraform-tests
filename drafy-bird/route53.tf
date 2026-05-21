
  # route53.tf
  data "aws_route53_zone" "main" {
    zone_id = var.hosted_zone_id
  }

  resource "aws_route53_record" "drafty_bird" {
    zone_id = data.aws_route53_zone.main.zone_id
    name    = var.domain
    type    = "A"

    alias {
      name                   = aws_cloudfront_distribution.drafty_bird.domain_name
      zone_id                = aws_cloudfront_distribution.drafty_bird.hosted_zone_id
      evaluate_target_health = false   # CloudFront doesn't support health checks on alias
    }
  }