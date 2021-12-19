

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
  filename = ".artefacts/${aws_key_pair.kp.key_name}.pem"
  content = tls_private_key.pk.private_key_pem

  provisioner "local-exec" {
    command = "chmod 0700 .artefacts/${aws_key_pair.kp.key_name}.pem"
  }
}

resource "aws_security_group" "main" {
  egress = [
    {
      description       = ""
      from_port         = 0
      protocol          = "-1"
      self              = false
      to_port           = 0
      cidr_blocks       = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = []
      prefix_list_ids   = []
      security_groups   = []
    }
  ]
  ingress = [
    {
      description       = "SSH Port"
      from_port         = 22
      to_port           = 22
      protocol          = "tcp"
      self              = false
      cidr_blocks       = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = []
      prefix_list_ids   = []
      security_groups   = []
    },
    {
      description       = "K8S API"
      from_port         = 6443
      to_port           = 6443
      protocol          = "tcp"
      self              = false
      cidr_blocks       = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = []
      prefix_list_ids   = []
      security_groups   = []
    }
  ]
}

output "local_ssh_key" {
  value = local_file.ssh_key.filename
}


resource "aws_spot_instance_request" "master" {
  ami                    = data.aws_ami.ubuntu.id
  spot_price             = var.ec2_spot_price
  instance_type          = "t2.large"
  wait_for_fulfillment   = true
  spot_type              = "one-time"
  key_name               = aws_key_pair.kp.key_name
  vpc_security_group_ids = [aws_security_group.main.id]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "20"
    delete_on_termination = true
  }

  connection {
    host = self.public_ip
    user = "ubuntu"
    private_key = local_file.ssh_key.content
  }

  provisioner "remote-exec" {
    inline = [
      "wget https://training.linuxfoundation.org/cm/LFD259/LFD259_V2021-12-09_SOLUTIONS.tar.xz --user=${var.lfd259_username} --password=${var.lfd259_password}",
      "tar -xf LFD259_V2021-12-09_SOLUTIONS.tar.xz",
      "cd LFD259/SOLUTIONS/s_02/",
      "bash k8scp.sh | tee $HOME/cp.out",
      "echo \"source <(kubectl completion bash)\" >> $HOME/.bashrc",
    ]
  }

  # can't find how to read remote file and store it into variable.
  # So, here is workaround: store join command into join.sh file, copy to local, read to variable, execute on worker.
  provisioner "remote-exec" {
    inline = [
      "kubeadm token create --print-join-command > join.sh",
    ]
  }


  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./.artefacts/myKey.pem ubuntu@${self.public_ip}:~/join.sh .artefacts/join.sh"
  }
}

data "local_file" "join_sh" {
  filename = ".artefacts/join.sh"
  depends_on = [
    aws_spot_instance_request.master
  ]
}


resource "aws_spot_instance_request" "worker" {
  ami                    = data.aws_ami.ubuntu.id
  spot_price             = var.ec2_spot_price
  instance_type          = "t2.large"
  wait_for_fulfillment   = true
  spot_type              = "one-time"
  key_name               = aws_key_pair.kp.key_name
  vpc_security_group_ids = [aws_security_group.main.id]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "20"
    delete_on_termination = true
  }

  connection {
    host = self.public_ip
    user = "ubuntu"
    private_key = local_file.ssh_key.content
  }

  provisioner "remote-exec" {
    inline = [
      "wget https://training.linuxfoundation.org/cm/LFD259/LFD259_V2021-12-09_SOLUTIONS.tar.xz --user=${var.lfd259_username} --password=${var.lfd259_password}",
      "tar -xf LFD259_V2021-12-09_SOLUTIONS.tar.xz",
      "cd LFD259/SOLUTIONS/s_02/",
      "bash k8sSecond.sh",
      "sudo apt-get install bash-completion vim -y",
      "echo \"source <(kubectl completion bash)\" >> $HOME/.bashrc",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo '${data.local_file.join_sh.content}'",
      "sudo ${data.local_file.join_sh.content}"
    ]
  }

  depends_on = [
    aws_spot_instance_request.master,
    data.local_file.join_sh
  ]


}

output "ec2_master_ip" {
  value = aws_spot_instance_request.master.public_ip
}

output "ec2_worker_ip" {
  value = aws_spot_instance_request.worker.public_ip
}
