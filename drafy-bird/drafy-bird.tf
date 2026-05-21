

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# outputs.tf
output "cloudfront_domain" {
  description = "CloudFront distribution domain — set this as the ALB origin"
  value       = aws_cloudfront_distribution.drafty_bird.domain_name
}

output "cloudfront_distribution_id" {
  description = "Used for cache invalidations in CI"
  value       = aws_cloudfront_distribution.drafty_bird.id
}

# How alb_dns_name gets its value in practice:

# # terraform.tfvars (or fed from a data source / remote state)
# alb_dns_name   = "k8s-istiosys-xxx.us-east-1.elb.amazonaws.com"
# hosted_zone_id = "Z1234ABCDEF"

# Or pull it automatically if your cluster Terraform and this Terraform share state:

data "kubernetes_service" "istio_gateway" {
  metadata {
    name      = "istio-ingressgateway"
    namespace = "istio-system"
  }
}

variable "alb_dns_name" {
  default = null
}

locals {
  alb_dns_name = coalesce(var.alb_dns_name,
data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].hostname)
}
