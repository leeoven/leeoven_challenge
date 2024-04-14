data "aws_route53_zone" "dns_zone" {
  name         = var.root_domain
  private_zone = false
}

resource "aws_acm_certificate" "ssl_certificate" {
  domain_name               = var.root_domain
  subject_alternative_names = ["*.${var.root_domain}"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "dns_validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.ssl_certificate.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.ssl_certificate.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.ssl_certificate.domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.dns_zone.zone_id
  ttl             = var.dns_record_ttl
}

resource "aws_acm_certificate_validation" "ssl_validation" {
  certificate_arn         = aws_acm_certificate.ssl_certificate.arn
  validation_record_fqdns = [aws_route53_record.dns_validation.fqdn]
}

resource "aws_cloudfront_origin_access_control" "cloudfront_s3_oac" {
    name                              = "OAC for S3 Buckets"
    description                       = "Origin Access Control For Website Bucket"
    origin_access_control_origin_type = "s3"
    signing_behavior                  = "always"
    signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website_distribution" {
    enabled = true
    is_ipv6_enabled = true
    default_root_object = var.index_document
    aliases = [var.root_domain]
    
    origin {
        domain_name = var.bucket_regional_domain_name
        origin_id = "S3-${var.s3_bucket_id}"
        origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_s3_oac.id
    }

    default_cache_behavior {
        allowed_methods = ["GET", "HEAD"]
        cached_methods = ["GET", "HEAD"]
        # Using AWS Managed-CachingOptimized cache policy
        cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
        target_origin_id = "S3-${var.s3_bucket_id}"
        viewer_protocol_policy = "redirect-to-https"
    } 

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    viewer_certificate {
        acm_certificate_arn = aws_acm_certificate.ssl_certificate.arn
        ssl_support_method = "sni-only"
        minimum_protocol_version = "TLSv1.2_2021"
    }
}

resource "aws_s3_bucket_policy" "cloudfront_oac_policy" {
  bucket = var.s3_bucket_id

  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForCloudFrontPrivateContent"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${var.s3_bucket_id}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website_distribution.arn
          }
        }
      }
    ]
  })
}

resource "aws_route53_record" "website_alias_record" {
    zone_id = data.aws_route53_zone.dns_zone.zone_id
    name    = var.root_domain
    type    = "A"

    alias {
        name                   = aws_cloudfront_distribution.website_distribution.domain_name
        zone_id                = aws_cloudfront_distribution.website_distribution.hosted_zone_id
        evaluate_target_health = true
    }
}