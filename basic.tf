# connection to AWS
provider "aws" {
  profile    = "default"
  region     = var.region
}
#end connection to AWS

# create the VPC
resource "aws_vpc" "vpc1" {
  cidr_block           = var.vpcCIDRblock
  instance_tenancy     = var.instanceTenancy 
  enable_dns_support   = var.dnsSupport 
  enable_dns_hostnames = var.dnsHostNames
  
} # end resource

# create the internet gateway
resource "aws_internet_gateway" "gateway1" {
  vpc_id = aws_vpc.vpc1.id
  
}
# end internet gateway

# create the Subnet
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = var.subnetCIDRblock
  map_public_ip_on_launch = var.mapPublicIP 
  availability_zone       = var.availabilityZone
 
} # end resource
# create the Subnet
resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = var.subnetCIDRblock2
  map_public_ip_on_launch = var.mapPublicIP
  availability_zone       = var.availabilityZone2
 
} # end resource

# Create the Security Group
resource "aws_security_group" "securitygroup1" {
  vpc_id       = aws_vpc.vpc1.id
  name         = "Security Group 1"
  description  = "Security Group 1"
  
  # allow ingress of port 22
  ingress {
    cidr_blocks = var.ingressCIDRblock  
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  } 
  
  # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
} # end resource

#Public key
resource "aws_key_pair" "ec2key" {
  key_name = "ec2key1"
  public_key = file(var.public_key_path)
}
#end Public key

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

#Resources


#Server instance
resource "aws_instance" "ec21" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = aws_key_pair.ec2key.key_name
  vpc_security_group_ids = [aws_security_group.securitygroup1.id]
  subnet_id = aws_subnet.subnet1.id

}
#End server instane


resource "aws_db_subnet_group" "dbsubnet1" {
  name       = "dbsubnet1"
  subnet_ids = [aws_subnet.subnet1.id,aws_subnet.subnet2.id]
}
#DB instance
resource "aws_db_instance" "db1" {
  name = "db1"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  username             = "root"
  password             = "miso4202-202002"
  parameter_group_name = "default.mysql5.7"
  vpc_security_group_ids = [aws_security_group.securitygroup1.id]
  db_subnet_group_name = aws_db_subnet_group.dbsubnet1.name
}
#End db instance

#EBS instance
resource "aws_ebs_volume" "ebs1" {
  availability_zone = var.availabilityZone
  size              = 40
}
#end EBS instance

#EBS attachment
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs1.id
  instance_id = aws_instance.ec21.id
}
#END EBS attachment