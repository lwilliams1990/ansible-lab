# Gather Ubuntu 18.04 Latest AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Create 3 Ubuntu 18.04 Instances
resource "aws_instance" "lw-lab-nodes" {
  count         = 3
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.lw-lab-subnet.id
  vpc_security_group_ids      = [aws_security_group.lw-lab-sg.id]
  

  tags = {
    Name  = "lw-lab-0${count.index + 1}"
    Env   = "lab"
  }

  key_name = "lw"
}

# Create Bastion Host
resource "aws_instance" "lw-lab-bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.lw-lab-subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.lw-lab-sg.id]

  tags = {
    Name = "lw-lab-bst"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install software-properties-common",
      "sudo apt-add-repository --yes --update ppa:ansible/ansible",
      "sudo apt install ansible -y",
      #"sudo apt-get install python3-pip -y",
      "sudo apt install python-pip -y",
      "pip install boto3",
    ]

      connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/home/luke/.ssh/lw.pem")
      host        = self.public_ip
    }
  }

  provisioner "file"{
    source      = "/home/luke/.ssh/lw.pem"
    destination = "/home/ubuntu/.ssh/lw.pem"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/home/luke/.ssh/lw.pem")
      host        = self.public_ip
    }
  }
  
  provisioner "file"{
    source      = "aws_ec2.yml"
    destination = "/home/ubuntu/aws_ec2.yml"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/home/luke/.ssh/lw.pem")
      host        = self.public_ip
    }
  }

  provisioner "file"{
    source      = "ansible.cfg"
    destination = "/home/ubuntu/ansible.cfg"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/home/luke/.ssh/lw.pem")
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /home/ubuntu/ansible.cfg /etc/ansible/ansible.cfg",
      "chmod 700 /home/ubuntu/.ssh/lw.pem",
    ]

      connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/home/luke/.ssh/lw.pem")
      host        = self.public_ip
    }
  }

  key_name = "lw"
}