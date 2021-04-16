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

resource "aws_subnet" "TestSubnet1" {
  depends_on         = [aws_vpc.TestVPC]
  availability_zone = "us-east-1a"
  vpc_id             = "${aws_vpc.TestVPC.id}"
  cidr_block         = "10.0.1.0/24"
}

resource "aws_subnet" "TestSubnet2" {
  depends_on         = [aws_vpc.TestVPC]
  availability_zone = "us-east-1b"
  vpc_id             = "${aws_vpc.TestVPC.id}"
  cidr_block         = "10.0.2.0/24"
}

resource "aws_internet_gateway" "TestGW" {
  vpc_id = "${aws_vpc.TestVPC.id}"
}

resource "aws_route_table" "TestRT" {
  vpc_id = "${aws_vpc.TestVPC.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.TestGW.id}"
  }
}

resource "aws_route_table_association" "TestRTA1" {
  subnet_id      = "${aws_subnet.TestSubnet1.id}"
  route_table_id = "${aws_route_table.TestRT.id}"
}

resource "aws_route_table_association" "TestRTA2" {
  subnet_id      = "${aws_subnet.TestSubnet2.id}"
  route_table_id = "${aws_route_table.TestRT.id}"
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
}

resource "aws_lb" "TestLB" {
  depends_on         = [aws_security_group.TestSG, aws_subnet.TestSubnet1, aws_subnet.TestSubnet2]
  name               = "TestLB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.TestSG.id}"]
  subnets            = ["${aws_subnet.TestSubnet1.id}", "${aws_subnet.TestSubnet2.id}"]
}

resource "aws_lb_listener" "TestLB" {
  depends_on        = [aws_lb.TestLB]
  load_balancer_arn = aws_lb.TestLB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.TestTG.arn}"
  }
}

// Configure the aws launch template
resource "aws_launch_template" "TestLT" {
  name_prefix            = "test-"
  image_id               = "ami-0742b4e673072066f"
  instance_type          = "t2.micro"
  key_name               = "default"
  user_data              = filebase64("init.sh")
  network_interfaces {
    associate_public_ip_address = true
    security_groups      = ["${aws_security_group.TestSG.id}"]
  }
}

// Configure the autoscaling group
resource "aws_autoscaling_group" "TestASG" {
  name                      = "TestASG"
  depends_on                = [aws_launch_template.TestLT]
  desired_capacity          = 4
  max_size                  = 5
  min_size                  = 3
  target_group_arns         = ["${aws_lb_target_group.TestTG.arn}"]
  vpc_zone_identifier       = ["${aws_subnet.TestSubnet1.id}", "${aws_subnet.TestSubnet2.id}"]

  launch_template {
    id        = aws_launch_template.TestLT.id
    version   = "$Latest"
  }
}