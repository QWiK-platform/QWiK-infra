# iac/base/cloudfront.tf

# -------------------------
# Origin Access Identity (OAI)
# -------------------------

resource "aws_cloudfront_origin_access_identity" "qwik_frontend_oai" {
  comment = "OAI for QWiK Frontend Bucket"
}

# -------------------------
# CloudFront Distribution (CDN) 
# -------------------------

resource "aws_cloudfront_distribution" "qwik_frontend_cdn" {
  # Origin
  origin {
    domain_name = aws_s3_bucket.qwik_frontend_bucket.bucket_regional_domain_name
    origin_id   = "S3-QWiK-Frontend"

    # OAI 연결
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.qwik_frontend_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html" # 루트 접속 시 index.html 반환

  # 캐시 동작 설정 (기본값)
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-QWiK-Frontend"

    viewer_protocol_policy = "redirect-to-https" # HTTPS 강제

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # 뷰어(사용자) 설정
  restrictions {
    geo_restriction {
      restriction_type = "none" # 모든 국가 접속 허용
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # 기본 *.cloudfront.net 인증서 사용
  }

  tags = {
    Name = "QWiK-Frontend-CDN"
  }
}
