# cloudfront.tf
resource "aws_cloudfront_distribution" "drafty_bird" {
    enabled             = true
    aliases             = [var.domain]
    http_version        = "http2and3"
    price_class         = "PriceClass_100"   # US + Europe edge locations

    # ── Origin: the ALB ──────────────────────────────────────────────
    origin {
        origin_id   = "alb"
        domain_name = var.alb_dns_name          # <-- your variable

        custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
        }
    }

    # ── Cache behaviours ─────────────────────────────────────────────
    # Static assets — cache at edge
    ordered_cache_behavior {
        path_pattern           = "/assets/*"
        target_origin_id       = "alb"
        viewer_protocol_policy = "redirect-to-https"
        allowed_methods        = ["GET", "HEAD"]
        cached_methods         = ["GET", "HEAD"]
        compress               = true

        forwarded_values {
        query_string = false
        cookies { forward = "none" }
        }

        min_ttl     = 0
        default_ttl = 86400
        max_ttl     = 31536000
    }

    # API paths — bypass cache, forward to origin
    dynamic "ordered_cache_behavior" {
    for_each = toset(["/score", "/leaderboard", "/game-start"])
    content {
        path_pattern           = ordered_cache_behavior.value
        target_origin_id       = "alb"
        viewer_protocol_policy = "redirect-to-https"
        allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods         = ["GET", "HEAD"]
        compress               = true

        forwarded_values {
        query_string = true
        headers      = ["Host", "Authorization", "x-request-id"]
        cookies { forward = "none" }
        }

        min_ttl     = 0
        default_ttl = 0
        max_ttl     = 0
    }
    }

    # Default — catch-all (serves index.html for SPA routing)
    default_cache_behavior {
        target_origin_id       = "alb"
        viewer_protocol_policy = "redirect-to-https"
        allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods         = ["GET", "HEAD"]
        compress               = true

        forwarded_values {
        query_string = true
        headers      = ["Host", "Authorization", "x-request-id"]
        cookies { forward = "none" }
        }

        min_ttl     = 0
        default_ttl = 0
        max_ttl     = 0
    }

    # ── TLS ──────────────────────────────────────────────────────────
    viewer_certificate {
        acm_certificate_arn      = aws_acm_certificate_validation.drafty_bird.certificate_arn
        ssl_support_method       = "sni-only"
        minimum_protocol_version = "TLSv1.2_2021"
    }

    # ── WAF ──────────────────────────────────────────────────────────
    web_acl_id = aws_wafv2_web_acl.drafty_bird.arn

    restrictions {
        geo_restriction { restriction_type = "none" }
    }


    #   1. Custom error responses — critical for SPA
                                                                        
    #   Without this, if a user navigates directly to             
    #   drafty-bird.example.com/some-path, the ALB returns a 404 and
    #   CloudFront forwards that 404 to the browser. React never gets to
    #   handle the route:

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

    # Then reference it in each cache behavior:
    # response_headers_policy_id =
    # aws_cloudfront_response_headers_policy.security.id
    #  3. Access logging
  logging_config {
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "drafty-bird/"
    include_cookies = false
  }

  # Minor but worth having
  is_ipv6_enabled = true   # dual-stack, expected by modern clients
}


#    2. Security response headers policy
resource "aws_cloudfront_response_headers_policy" "security" {
    name = "drafty-bird-security-headers"

    security_headers_config {
        strict_transport_security {
            access_control_max_age_sec = 31536000
            include_subdomains         = true
            preload                    = true
            override                   = true
            }
            content_type_options  { override = true }
            frame_options         { 
            frame_option = "DENY" 
            override = true 
        }
        
        xss_protection        {
                mode_block = true 
                protection = true
            override = true 
        }
            
        referrer_policy       { 
            referrer_policy = "strict-origin-when-cross-origin" 
            override = true 
        }
    }
}
