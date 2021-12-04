################################################################
##
##  AWS S3
##

resource aws_s3_bucket main {
  bucket = var.bucket_name
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = var.bucket_name
  }
}

resource aws_s3_bucket_public_access_block main {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource aws_s3_bucket_policy main {
  bucket = aws_s3_bucket.main.id

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Id": "cloudfront-only",
      "Statement": [
        {
          "Action":   [
            "s3:ListBucket"
          ],
          "Effect":   "Allow",
          "Resource": ["${aws_s3_bucket.main.arn}"],
          "Principal": {
            "AWS": [
              "${aws_cloudfront_origin_access_identity.main.iam_arn}"
            ]
          }
        },
        {
          "Action":   [
            "s3:GetObject"
          ],
          "Effect":   "Allow",
          "Resource": ["${aws_s3_bucket.main.arn}/*"],
          "Principal": {
            "AWS": [
              "${aws_cloudfront_origin_access_identity.main.iam_arn}"
            ]
          }
        }
      ]
    }
    EOF
}
