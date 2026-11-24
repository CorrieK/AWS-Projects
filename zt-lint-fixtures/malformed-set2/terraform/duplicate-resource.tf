# Parses, but the same address is declared twice.
resource "aws_s3_bucket" "dup" { bucket = "one" }
resource "aws_s3_bucket" "dup" { bucket = "two" }
