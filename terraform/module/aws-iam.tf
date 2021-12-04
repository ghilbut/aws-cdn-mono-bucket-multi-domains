################################################################
##
##  AWS IAM
##

resource aws_iam_user main {
  name = var.bucket_name
  path = "/"
}

resource aws_iam_access_key main {
  user = aws_iam_user.main.name
}

resource aws_iam_user_policy main {
  name = "s3"
  user = aws_iam_user.main.name

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": [
            "s3:*"
          ],
          "Effect": "Allow",
          "Resource": [
            "${aws_s3_bucket.main.arn}",
            "${aws_s3_bucket.main.arn}/*"
          ]
        },
        {
          "Action": [
            "s3:CreateBucket*",
            "s3:DeleteBucket*",
            "s3:PutBucket*"
          ],
          "Effect": "Deny",
          "Resource": "${aws_s3_bucket.main.arn}"
        }
      ]
    }
    EOF
}
