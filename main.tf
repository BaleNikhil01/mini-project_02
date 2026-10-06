terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main"
  }
}

#Create a public subnet and link it up with vpc
resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Main"
  }
}

#Create a IGW
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

#Create a RT
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "example"
  }
}

#Create RT-assciation 
resource "aws_route_table_association" "example" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.example.id
}

#Create Security Groups
resource "aws_security_group" "example" {
  name   = "sg"
  vpc_id = aws_vpc.main.id

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
    cidr_blocks = ["45.115.52.151/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create EC2
resource "aws_instance" "web" {
  ami           = "ami-01a00762f46d584a1"
  instance_type = "t3.micro"

  subnet_id = aws_subnet.main.id

  vpc_security_group_ids = [
    aws_security_group.example.id
  ]

  associate_public_ip_address = true

  tags = {
    Name = "terraform-ec2"
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

terraform {
  backend "s3" {
    bucket       = "mini-project-02-terraform-state"
    key          = "mini-project-02/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
  }
}

























