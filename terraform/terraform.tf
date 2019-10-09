provider "aws" 
{
	  region = "ap-southeast-1"
 
}


variable "instance-type" 
{
	  default = "t2.micro"
}

variable "ami" 
{
	  default = "ami-048a01c78f7bae4aa"
}

variable "key-name" 
{
 	 default = "ag"
}



resource "aws_vpc" "vpc" 
{
    cidr_block = "192.168.0.0/16"
    enable_dns_support = "true" #gives you an internal domain name
    enable_dns_hostnames = "true" #gives you an internal host name
    enable_classiclink = "false"
    instance_tenancy = "default"

    tags = 
	{
	        Name = "vpc"   
	}
}

resource "aws_subnet" "subnet-public-1" 
{
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "192.168.1.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "ap-southeast-1a"
    tags = 
	{
	        Name = "subnet-public-1"    
	}
}
resource "aws_subnet" "subnet-public-2" 
{
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "192.168.2.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "ap-southeast-1b"
    tags = 
	{
 	       Name = "subnet-public-2"
	}
}

resource "aws_internet_gateway" "igw" 
{
    vpc_id = "${aws_vpc.vpc.id}"
    tags = 
	{
	        Name = "igw"
	}
}

resource "aws_route_table" "public-route" 
{
    vpc_id = "${aws_vpc.vpc.id}"

    route 
	{
		//associated subnet can reach everywhere
		cidr_block = "0.0.0.0/0"
		//CRT uses this IGW to reach internet
		gateway_id = "${aws_internet_gateway.igw.id}"
  	}

    tags = 
	{
	        Name = "public-crt" 
	}
}
resource "aws_route_table_association" "crta-public-subnet-1"
{
    subnet_id = "${aws_subnet.subnet-public-1.id}"
  
    route_table_id = "${aws_route_table.public-route.id}"
}

resource "aws_route_table_association" "crta-public-subnet-2"
{
    
    subnet_id = "${aws_subnet.subnet-public-2.id}"
    route_table_id = "${aws_route_table.public-route.id}"
}

resource "aws_security_group" "ssh" 
{
    vpc_id = "${aws_vpc.vpc.id}"

    egress 
	{
		from_port = 0
		to_port = 0
		protocol = -1
		cidr_blocks = ["0.0.0.0/0"]
	}
    ingress 
	{
		from_port = 22
		to_port = 22
		protocol = "tcp"
		// This means, all ip address are allowed to ssh !
		// Do not do it in the production.
		// Put your office or home address in it!
		cidr_blocks = ["0.0.0.0/0"]
	}
    //If you do not add this rule, you can not reach the NGIX
    ingress 
	{
		from_port = 8080
		to_port = 8080
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
    tags = 
	{
	        Name = "ssh-allowed"    
	}
}

resource "aws_instance" "ec2" 
{
  ami = "${var.ami}"
  instance_type = "${var.instance-type}"
  key_name = "${var.key-name}"
  tags = 
	{
	    "Name" = "CI"
	}
  security_groups = ["${aws_security_group.ssh.id}"]
  subnet_id = "${aws_subnet.subnet-public-1.id}"

  provisioner "remote-exec" 
 {
    inline = [
    "sudo yum update -y",
    "sudo amazon-linux-extras install nginx1 -y",
    "sudo amazon-linux-extras install",
    "sudo service nginx start"]

 }
  connection 
 {
    type     = "ssh"
    host = "${aws_instance.ec2.public_ip}"
    user     = "ec2-user"
    password = ""
    private_key = "${file("/home/ajju/Documents/singapor_key/ag.pem")}"
  }
}
resource "aws_instance" "ec2-1" 
{
  ami = "${var.ami}"
  instance_type = "${var.instance-type}"
  key_name = "${var.key-name}"
  tags = 
  {
    "Name" = "CD"
  }
  security_groups = ["${aws_security_group.ssh.id}"]
  subnet_id = "${aws_subnet.subnet-public-2.id}"
}
  
resource "aws_instance" "ec2-2" 
{
  ami = "${var.ami}"
  instance_type = "${var.instance-type}"
  key_name = "${var.key-name}"
  tags = 
  {
    "Name" = "CD1"
  }
  security_groups = ["${aws_security_group.ssh.id}"]
  subnet_id = "${aws_subnet.subnet-public-1.id}"
}
resource "aws_instance" "ec2-3" 
{
  ami = "${var.ami}"
  instance_type = "${var.instance-type}"
  key_name = "${var.key-name}"
  tags = 
  {
    "Name" = "CD2"
  }
  security_groups = ["${aws_security_group.ssh.id}"]
  subnet_id = "${aws_subnet.subnet-public-1.id}"

  }
  

output "instance_ip" 
{
  value = "${aws_instance.ec2.public_ip}"
  
}
