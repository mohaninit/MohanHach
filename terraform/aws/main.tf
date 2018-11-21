provider "aws" {
  region = "${var.aws_region}"
}

##vpc##

resource "aws_vpc" "main" {
  cidr_block       = "${var.vpc_cidr}"

  tags {
    Name = "${var.vpc_name}"
  }
}

## subnets##
resource "aws_subnet" "us-east-1a-public" {
    vpc_id = "${aws_vpc.main.id}"

    cidr_block = "${var.public_subnet_cidr}"
    availability_zone = "us-east-1a"

    tags {
        Name = "Public Subnet"
    }
}

resource "aws_subnet" "us-east-1a-private" {
    vpc_id = "${aws_vpc.main.id}"

    cidr_block = "${var.private_subnet_cidr}"
    availability_zone = "us-east-1a"

    tags {
        Name = "Private Subnet"
    }
}
##internetgateway##
resource "aws_internet_gateway" "main" {
    vpc_id = "${aws_vpc.main.id}"
}

## Nat and EIP##
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.us-east-1a-public.id}"
}


##routetable and association### 
resource "aws_route_table" "us-east-1a-public" {
    vpc_id = "${aws_vpc.main.id}"

    route {
        cidr_block = "${var.public_route_cidr}"
        gateway_id = "${aws_internet_gateway.main.id}"
    }

    tags {
        Name = "Public Route"
    }
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.us-east-1a-public.id}"
  route_table_id = "${aws_route_table.us-east-1a-public.id}"
}


resource "aws_route_table" "us-east-1a-private" {
    vpc_id = "${aws_vpc.main.id}"

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.nat.id}"
    }

    tags {
        Name = "Private Subnet"
    }
}

resource "aws_route_table_association" "private" {
  subnet_id      = "${aws_subnet.us-east-1a-private.id}"
  route_table_id = "${aws_route_table.us-east-1a-private.id}"
}

## Security group##
resource "aws_security_group" "Public" {
  name        = "Public"
  description = "Allow  inbound traffic"

  ingress {
    from_port = 80
    to_port = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.public_sg_cidr}"]
  }
  
  ingress {
    from_port = 22
    to_port = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.public_sg_cidr}"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "Public_Sg"
  }
}


resource "aws_security_group" "Private" {
  name        = "private"
  description = "private inbound traffic"

  ingress {
    from_port   = 1881
    to_port     = 1881
    protocol    = "tcp"
    cidr_blocks = ["${var.private_sg_cidr}"]
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["${var.private_sg_cidr}"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.private_sg_cidr}"]
  }
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
   egress {
     from_port = 443
     to_port = 443
     protocol = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
    }
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "Private_Sg"
  }
}


## instances##

resource "aws_instance" "Bastion" {
    ami = "${var.amis}"
    availability_zone = "us-east-1a"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.Public.id}"]
    subnet_id = "${aws_subnet.us-east-1a-public.id}"
    associate_public_ip_address = true
    source_dest_check = false
     
    user_data = <<-EOF
             #!bin/bash
             sudo apt-get install software-properties-common -y
             sudo apt-add-repository ppa:ansible/ansible  -y
             sudo apt-get update -y
             sudo apt-get install ansible -y
             EOF
    tags {
        Name = "Bastion"
    }
}


resource "aws_instance" "Nginx" {
    ami = "${var.amis}"
    availability_zone = "us-east-1a"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.Public.id}"]
    subnet_id = "${aws_subnet.us-east-1a-public.id}"
    associate_public_ip_address = true
    source_dest_check = false


    tags {
        Name = "Nginx"
    }
}




resource "aws_instance" "Node" {
    ami = "${var.amis}"
    availability_zone = "us-east-1a"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.Private.id}"]
    subnet_id = "${aws_subnet.us-east-1a-private.id}"
    associate_public_ip_address = true
    source_dest_check = false


    tags {
        Name = "Node"
    }
}

##Elb## 

resource "aws_elb" "MyElb" {
  name               = "MyElb"
  # availability_zones = ["us-east-1a"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = ["${aws_instance.Nginx.id}"]
  subnets                     = ["${aws_subnet.us-east-1a-public.id}"]
  security_groups             = ["${aws_security_group.Public.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
  
  tags {
    Name = "MyElb"
  }
}
