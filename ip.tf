resource "aws_eip" "server_ip" {}

output "show_server_ip" {
  value = aws_eip.server_ip.public_ip
}

