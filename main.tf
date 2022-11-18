terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.40.0"
    }
  }
}

provider "aws" {
  # Configuration options
}


data "aws_vpc" "df_vpc" {
  default = true
}



data "aws_ami" "ec2-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm*"]
  }
}

resource "aws_security_group" "docker-sg" {
  name        = "docker-sg"
  description = "Allow 80 and 22"
  vpc_id      = data.aws_vpc.df_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}



resource "aws_instance" "Docker-Compose-instance" {
  ami             = data.aws_ami.ec2-ami.id
  instance_type   = "t2.micro"
  vpc_security_group_ids = [aws_security_group.docker-sg.id]
  key_name        = "******" # Your key_name without .pem

  tags = {
    Name = "Docker-Compose-instance"
  }

  user_data = <<-EOF
              #! /bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              # install docker-compose
              curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname -s)-$(uname -m)" \
              -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              yum install git -y
              hostnamectl set-hostname "docker-compose-server"
              TOKEN="*****************************************"
              cd /home/ec2-user && git clone https://$TOKEN@github.com/MehmetSadik/bookstore.git # !!! Your repository address and TOKEN
              cd bookstore/    # !!! change directory
              docker-compose up -d           
              EOF             

}

output "docker-compose-public_ip" {
  value = aws_instance.Docker-Compose-instance.public_ip
}
