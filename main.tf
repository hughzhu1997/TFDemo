provider "aws" {
  region = "ap-southeast-2"
}


variable vpc_cidr_blocks {}
variable subnet_cidr_blocks {}
variable availability_zone {}
variable env_prefix {}

# Create a VPC
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_blocks
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
 }


# Create a Subnet
resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_blocks
    availability_zone = var.availability_zone
    tags = {
   Name: "${var.env_prefix}-subnet-1"
}
}



# Create a Route-Table
resource "aws_route_table" "myapp-RT" {
     vpc_id = aws_vpc.myapp-vpc.id

     route {
         cidr_block = "0.0.0.0/0"
         gateway_id = aws_internet_gateway.myapp-igw.id

     }
   tags = {
   Name: "${var.env_prefix}-myapp-RT"
}
     
}

resource "aws_route_table_association" "rtb-myapp-subnet-1" {
      subnet_id = aws_subnet.myapp-subnet-1.id
      route_table_id = aws_route_table.myapp-RT.id
  
}

# Create an Internet-Gateway to access to internet
resource "aws_internet_gateway" "myapp-igw" {
      vpc_id = aws_vpc.myapp-vpc.id
      tags = {
         Name: "${var.env_prefix}-myapp-igw"
          }
}

# Create a Security Group
resource "aws_security_group" "myapp-sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      =  aws_vpc.myapp-vpc.id

  ingress {
    description      = "Port from HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

 
  ingress {
    description      = "PORT FROM TELET"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }

  ingress {
    description      = "FOR HTTP "
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
   cidr_blocks      = ["0.0.0.0/0"]
    
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
         Name: "${var.env_prefix}-myapp-sg"
          }
}

# Output AWS AMI IMAGES INFORMATION
data "aws_ami" "latest-amazon-linux-image" {
   most_recent      = true
   owners           = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

# output "aws_ami_id" {
#   value = data.aws_ami.latest-amazon-linux-image.id
  
# }

# # Create an EC2 Instance
resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = "t2.micro"
  
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.availability_zone

  associate_public_ip_address = true
  key_name = "key-pair"
 
  
  
}
