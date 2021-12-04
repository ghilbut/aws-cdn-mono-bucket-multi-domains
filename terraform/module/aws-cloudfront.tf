################################################################
##
##  AWS CloudFront
##

resource aws_cloudfront_origin_access_identity main {
  comment = lookup(var.default_tags, "purpose", "")
}

##--------------------------------------------------------------
##  production

resource aws_cloudfront_distribution main {
  depends_on = [
    aws_route53_record.aws_acm_certificate,
  ]

  origin {
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.main.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  custom_error_response {
    error_caching_min_ttl = 0
    error_code = 404
    response_code = 404
    response_page_path = "/404.html"
  }

  aliases = var.fqdns

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.main.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"

    min_ttl     = var.cf_caches_ttl.min
    default_ttl = var.cf_caches_ttl.default
    max_ttl     = var.cf_caches_ttl.max

    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = aws_lambda_function.main.qualified_arn
      include_body = false
    }
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      #restriction_type = "whitelist"
      #locations        = ["KR"]
    }
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.main.arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2018"
    ssl_support_method             = "sni-only"
  }
}
