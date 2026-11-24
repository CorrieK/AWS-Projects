resource "aws_instance" "i" {
  user_data = <<-EOT
    #!/bin/bash
    echo never terminated
}
