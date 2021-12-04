################################################################
##
##  AWS Lambda@Edge
##

locals {
  lambda_function_name = var.bucket_name
  lambda_filename = "main"
}

resource aws_lambda_function main {
  depends_on = [
    aws_cloudwatch_log_group.lambda,
  ]

  function_name = local.lambda_function_name
  role          = aws_iam_role.lambda.arn

  handler = "${local.lambda_filename}.lambda_handler"
  publish = true
  runtime = "python3.9"

  s3_bucket         = aws_s3_bucket.main.id
  s3_key            = aws_s3_bucket_object.lambda.id
  s3_object_version = aws_s3_bucket_object.lambda.version_id
  source_code_hash  = filebase64sha256(data.archive_file.lambda.output_path)

  lifecycle {
    ignore_changes = [
      last_modified,
    ]
  }
}

resource aws_iam_role lambda {
  name               = local.lambda_function_name
  description        = local.lambda_function_name
  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Effect": "Allow",
          "Principal": {
            "Service": [
              "edgelambda.amazonaws.com",
              "lambda.amazonaws.com"
            ]
          }
        }
      ]
    }
    EOF

  inline_policy {
    name = "logs"
    policy = <<-EOF
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Action": [
              "s3:ListBucket",
              "s3:GetObject*"
            ],
            "Effect": "Allow",
            "Resource": [
              "${aws_s3_bucket.main.arn}",
              "${aws_s3_bucket.main.arn}/*"
            ]
          },
          {
            "Action": [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Effect": "Allow",
            "Resource": [
              "${aws_cloudwatch_log_group.lambda.arn}:*"
            ]
          }
        ]
      }
      EOF
  }
}

resource aws_s3_bucket_object lambda {
  bucket = aws_s3_bucket.main.id
  key    = "lambda.zip"
  source = data.archive_file.lambda.output_path
  etag   = filemd5(data.archive_file.lambda.output_path)
}

data archive_file lambda {
  type        = "zip"
  output_path = "out/lambda.zip"

  source {
    content  = data.template_file.lambda.rendered
    filename = "${local.lambda_filename}.py"
  }
}

data template_file lambda {
  template = file("${path.module}/lambda/main.py")
  vars = {
    bucket_name = var.bucket_name
  }
}

resource aws_cloudwatch_log_group lambda {
  name = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = 3
}