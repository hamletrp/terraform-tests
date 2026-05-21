  # acm.tf — must be in us-east-1 for CloudFront

  resource "aws_acm_certificate" "drafty_bird" {
    provider          = aws.us_east_1
    domain_name       = var.cert_domain
    validation_method = "DNS"

    lifecycle {
      create_before_destroy = true
    }
  }

  resource "aws_route53_record" "cert_validation" {
    for_each = {
      for dvo in aws_acm_certificate.drafty_bird.domain_validation_options : dvo.domain_name =>
        dvo
    }

    zone_id = var.hosted_zone_id
    name    = each.value.resource_record_name
    type    = each.value.resource_record_type
    records = [each.value.resource_record_value]
    ttl     = 60
  }

  resource "aws_acm_certificate_validation" "drafty_bird" {
    provider                = aws.us_east_1
    certificate_arn         = aws_acm_certificate.drafty_bird.arn
    validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
  }