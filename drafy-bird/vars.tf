# variables.tf                                                                                 
  variable "alb_dns_name" {              
    description = "DNS name of the AWS ALB (from the Istio Gateway Service)"
    type        = string                                                                         
    # e.g. "k8s-istiosys-xxx.us-east-1.elb.amazonaws.com"   
  }

  variable "domain" {
    description = "App hostname"
    type        = string
    default     = "drafty-bird.example.com"
  }

variable "cert_domain" {
    description = "App hostname"
    type        = string
    default     = "*.example.com"
  }

  variable "hosted_zone_id" {
    description = "Route 53 hosted zone ID for example.com"
    type        = string
  }