

provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners = [var.ubuntu_account_number]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

variable "ubuntu_account_number" {
  default = "099720109477" # Canonical
}


resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "myKey"       # Create a "myKey" to AWS!!
  public_key = tls_private_key.pk.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.kp.key_name}.pem"
  content = tls_private_key.pk.private_key_pem

  provisioner "local-exec" {
    command = "chmod 0700 ${aws_key_pair.kp.key_name}.pem"
  }
}


resource "aws_security_group" "main" {
  egress = [
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
  ingress                = [
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
      description      = ""
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    }
  ]
}

resource "aws_spot_instance_request" "master" {
  ami                    = data.aws_ami.ubuntu.id
  spot_price             = var.ec2_spot_price
  instance_type          = "t2.large"
  wait_for_fulfillment   = true
  spot_type              = "one-time"
  key_name               = aws_key_pair.kp.key_name
  vpc_security_group_ids = [aws_security_group.main.id]
}

resource "aws_spot_instance_request" "worker" {
  ami                    = data.aws_ami.ubuntu.id
  spot_price             = var.ec2_spot_price
  instance_type          = "t2.large"
  wait_for_fulfillment   = true
  spot_type              = "one-time"
  key_name               = aws_key_pair.kp.key_name
  vpc_security_group_ids = [aws_security_group.main.id]
}

output "ec2_master_ip" {
  value = aws_spot_instance_request.master.public_ip
}

output "ec2_worker_ip" {
  value = aws_spot_instance_request.worker.public_ip
}
