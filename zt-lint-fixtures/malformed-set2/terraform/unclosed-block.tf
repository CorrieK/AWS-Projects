resource "aws_s3_bucket" "b" {
  bucket = "x"
  versioning {
    enabled = true
