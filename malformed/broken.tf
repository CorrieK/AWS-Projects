# INTENTIONALLY MALFORMED: parser must report an error, never crash.
resource "aws_instance" "bad" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  tags = {
    Name = "unterminated
  }
