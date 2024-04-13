# Lab 3. Terraform con AWS

En esta guía vamos a crear infraestructura en AWS, en concreto, crearemos una IP pública y una máquina virtual,
a la que le asociaremos esa IP, el grupo de seguridad por defecto y la clave SSH vockey; además, instalaremos el
servidor web NGINX y subiremos una página web.


## Proveedor y autenticación

```
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.44.0"
    }
  }
}

# Authentication and Configuration of the AWS Provider

provider "aws" {
  region     = "us-east-1"
  
  # ~/.aws/credentials
  profile = "default"

}
```

## IP

```
resource "aws_eip" "server_ip" {}

output "show_server_ip" {
  value = aws_eip.server_ip.public_ip
}
```

## Asociar IP a MV

```
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.server.id
  allocation_id = aws_eip.server_ip.id
}
```

## Máquina Virtual y Provisioners

```
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

}

output "show_server_ami" {
  value = data.aws_ami.ubuntu.id
}


resource "aws_instance" "server" {
  ami             = data.aws_ami.ubuntu.id #"ami-053053586808c3e70" #"ami-080e1f13689e07408"
  instance_type   = "t2.nano"
  key_name        = "vockey"
  security_groups = ["default"]

  tags = {
    Name = "Server"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = self.public_ip
    private_key = file("~/.ssh/labsuser.pem")
  }

  provisioner "file" {
    source      = "index.html"
    destination = "/home/ubuntu/index.html"
  }


  provisioner "remote-exec" {

    inline = [
      "sudo apt update", "sudo apt install nginx -y", "sudo mv /home/ubuntu/index.html /var/www/html"
    ]
  }


  provisioner "local-exec" {
    command    = "echo 'The server's IP address is ${self.private_ip}'"
    on_failure = continue
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Destroy-time provisioner'"
  }
  
}
```
