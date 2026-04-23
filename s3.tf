# s3.tf

resource "aws_s3_bucket" "st7-s3-bucket" {
    bucket = "st7-s3-bucket"
    tags = { Name = "st7-s3-bucket"}
}

# Bucket 버전 관리 설정
resource "aws_s3_bucket_versioning" "st7-s3-bucket-versioning" {
    bucket = aws_s3_bucket.st7-s3-bucket.id
    versioning_configuration {
      status = "Disabled"   # Enabled | Disabled | Suspended(중지)
    }
}

# Bucket Access 관리
# 정적 웹사이트 허용: false / default 값: true
resource "aws_s3_bucket_public_access_block" "st7-s3-bucket-access" {
    bucket = aws_s3_bucket.st7-s3-bucket.id
    # 1. 새로운 퍼블릭 ACL(권한 리스트) 추가를 막음: 누구나 들어오는 권한 추가 방지
    block_public_acls = false

    # 2. 기존에 설정된 모든 퍼블릭 ACL을 무시: 이미 부여된 외부 노출 권한이 있을 경우 취소
    ignore_public_acls = false

    # 3. 버킷 정책(Ebucket Policy)을 통해 외부인이 접근하는 것을 차단
    block_public_policy = false

    # 4. 퍼블릭 정책이 걸려있는 버킷에 대한 익명 접근을 제한
    restrict_public_buckets = false
}

# 정적 웹사이트 호스팅 기능 활성화
resource "aws_s3_bucket_website_configuration" "st7-s3-bucket-web-config" {
    bucket = aws_s3_bucket.st7-s3-bucket.id
    index_document {
      suffix = "index.html"
    }
    error_document {
      key = "error.html"
    }
}

# 버킷에 외부 접근에 대한 정책 정의
resource "aws_s3_bucket_policy" "st7-s3-bucket-policy" {
    bucket = aws_s3_bucket.st7-s3-bucket.id

    policy = jsonencode({
        "Version": "2012-10-17"
        "Statement": [
         {
            Sid = "Statement1"
            Effect = "Allow"
            Principal = "*"
            Action = "s3:GetObject"
            Resource = "${aws_s3_bucket.st7-s3-bucket.arn}/*"
         }
        ]
    })
}