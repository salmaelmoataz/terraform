provider "aws" {
    region = "us-east-1"
}



variable "public_key" {
}

variable "private_key" {
}

resource "aws_key_pair" "salom-key" {
  key_name = "salom-key"
  public_key = var.public_key
}

resource "aws_vpc" "salomvpc" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "salomsubnet" {
    vpc_id = aws_vpc.salomvpc.id
    cidr_block = "10.0.10.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "salomsubnet"
    }
}

output "vpcid" {
  value = aws_vpc.salomvpc.id
}

output "subnetid" {
  value = aws_subnet.salomsubnet.id
}

resource "aws_internet_gateway" "salomgate" {
  vpc_id = aws_vpc.salomvpc.id
  tags = {
      Name = "intgate"
  }
}

resource "aws_default_route_table" "salomdefault" {
    default_route_table_id = aws_vpc.salomvpc.default_route_table_id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.salomgate.id
    }
        tags = {
            Name = "salomroute"
        }
}

resource "aws_security_group" "salomsg" {
    name = "salomsg"
    vpc_id = aws_vpc.salomvpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0", ]
        self = false
  }
   ingress {
    protocol  = "tcp"
    from_port = 8080
    to_port   = 8080
    cidr_blocks = [ "0.0.0.0/0", ]
    self = false
  }
    ingress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    cidr_blocks = [ "0.0.0.0/0", ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ "0.0.0.0/0", ]
    self = false
  }
}

resource "aws_instance" "salom" {
    ami = "ami-0c02fb55956c7d316"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.salomsubnet.id
    vpc_security_group_ids = [aws_security_group.salomsg.id]
    associate_public_ip_address = true
    availability_zone = "us-east-1a"
    key_name = aws_key_pair.salom-key.key_name

connection {
    type = "ssh"
    host = self.public_ip
    port = 22
    user = "ec2-user"
    private_key = "${file(var.private_key)}"
    timeout = "4m"
    agent = false
}

provisioner "file" {
    source = "script.sh"
    destination = "/tmp/script.sh"
}

provisioner "file" {
    source = "phpscript.php"
    destination = "/tmp/phpscript.php"
}

provisioner "remote-exec" {
    inline = [
        "chmod +x /tmp/script.sh",
      "/tmp/script.sh args"
    ]
}

    tags = {
        Name = "salom"
    }
}