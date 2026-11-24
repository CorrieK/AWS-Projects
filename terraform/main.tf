# INTENTIONALLY INSECURE test fixture for zt-lint. DO NOT APPLY.
# Region: eu-west-1 (Ireland). Credentials below are AWS documentation dummies.

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# VIOLATION: hardcoded access key in provider block (dummy values)
provider "aws" {
  region     = "eu-west-1"
  access_key = "AKIAIOSFODNN7EXAMPLE"
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# VIOLATION: wildcard action on wildcard resource
resource "aws_iam_role" "wildcard" {
  name = "zt-fixture-wildcard-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "god_mode" {
  name = "god-mode"
  role = aws_iam_role.wildcard.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "this" {
  name = "zt-fixture-profile"
  role = aws_iam_role.wildcard.name
}

# VIOLATION: SSH, RDP and all ports open to the world; unrestricted egress
resource "aws_security_group" "open" {
  name        = "zt-fixture-open-sg"
  description = "Overly permissive SG (test fixture)"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RDP from anywhere"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description      = "All traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "test" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.open.id]
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = true

  # VIOLATION: IMDSv1 allowed
  metadata_options {
    http_tokens   = "optional"
    http_endpoint = "enabled"
  }

  # VIOLATION: unencrypted root volume
  root_block_device {
    volume_size = 8
    encrypted   = false
  }

  # VIOLATION: hardcoded access key (dummy values)
  user_data = <<-EOT
    #!/bin/bash
    export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
    export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
    export AWS_DEFAULT_REGION=eu-west-1
  EOT

  tags = {
    Name = "zt-fixture-insecure"
  }
}

output "instance_id" {
  value = aws_instance.test.id
}
