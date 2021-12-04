output s3_credential {
  value = {
    access_key = aws_iam_access_key.main.id
    secret_key = aws_iam_access_key.main.secret
  }
  sensitive = true
}
