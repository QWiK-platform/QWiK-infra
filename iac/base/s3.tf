# iac/base/s3.tf

# -------------------------
# S3 Bucket
# -------------------------

# 프론트엔드 정적 파일 호스팅용 S3 버킷

resource "aws_s3_bucket" "qwik_frontend_bucket" {
  bucket = var.qwik_frontend_bucket_name

  tags = {
    Name        = "QWiK-Frontend-Bucket-${var.environment}"
    Environment = var.environment
  }
}

# FE S3 Bucket Public Access 차단

resource "aws_s3_bucket_public_access_block" "qwik_frontend_bucket_pab" {
  # Bucket 연결
  bucket = aws_s3_bucket.qwik_frontend_bucket.id

  # 차단 설정
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# FE S3 Bucket Policy
# CloudFront OAI에게만 GetOnject 접근 권한 허용

resource "aws_s3_bucket_policy" "qwik_frontend_bucket_policy" {
  # Bucket 연결
  bucket = aws_s3_bucket.qwik_frontend_bucket.id

  # Policy 설정
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          # cloudfront.tf에서 정의할 OAI의 ARN을 참조
          AWS = aws_cloudfront_origin_access_identity.qwik_frontend_oai.iam_arn
        },
        Action   = "s3:GetObject", # 파일 읽기만 허용
        Resource = "${aws_s3_bucket.qwik_frontend_bucket.arn}/*"
      }
    ]
  })
}

