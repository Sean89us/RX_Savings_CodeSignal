terraform {
  required_version = "0.15.0"
  required_providers {
    aws = {
      source    = "hashicorp/aws"
      version   = "~> 3.0"
    }
  }
}

// Configure the AWS Provider
provider "aws" {
  region      = "us-east-1"
}

// Create a VPC
resource "aws_vpc" "TestVPC" {
  cidr_block  = "10.0.0.0/16"
}


resource "aws_lb_target_group" "TestTG" {
  name        = "TestTG"
  depends_on  = [aws_vpc.TestVPC]
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.TestVPC.id}"
  target_type = "instance"
}

resource "aws_security_group" "TestSG" {
  name        = "TestSG"
  description = "Test Security Group"
  vpc_id      = "${aws_vpc.TestVPC.id}"

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSL from anywhere"
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

  tags = {
    Name = "allow_tls"
  }
}

// Configure the aws launch template
resource "aws_launch_template" "TestLT" {
  name_prefix   = "test-"
  image_id      = "ami-0742b4e673072066f"
  instance_type = "t2.micro"
  key_name      = "default"
  user_data     = "${base64encode(file("init.sh"))}"
  vpc_security_group_ids = ["${aws_security_group.TestSG.id}"]
  network_interfaces {
    subnet_id   = "${aws_vpc.TestVPC.id}"
  }
}

// Configure the autoscaling group
resource "aws_autoscaling_group" "TestASG" {
  name                      = "TestASG"
  depends_on                = [aws_launch_template.TestLT]
  availability_zones        = ["us-east-1a", "us-east-1b", "us-east-1c"]
  desired_capacity          = 1
  max_size                  = 2
  min_size                  = 1
  target_group_arns         = ["${aws_lb_target_group.TestTG.arn}"]


  launch_template {
    id        = aws_launch_template.TestLT.id
    version   = "$Latest"
  }
}