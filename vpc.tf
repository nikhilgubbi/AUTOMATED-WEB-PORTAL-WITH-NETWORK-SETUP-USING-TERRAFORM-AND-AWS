provider "aws" {
  region  = "ap-south-1"
}

resource "aws_vpc" "terra" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  

  tags = {
    Name = "terra"
  }
}


resource "aws_subnet" "main1" {
  vpc_id     = "${aws_vpc.terra.id}"
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "public"
  }
}


resource "aws_subnet" "main2" {
  vpc_id     = "${aws_vpc.terra.id}"
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1a"
 
  tags = {
    Name = "private"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.terra.id}"


  tags = {
    Name = "main"
  }
}


resource "aws_nat_gateway" "gw1"{
  allocation_id = "eipalloc-046a1ed9be66763ea"
  subnet_id      = "${aws_subnet.main2.id}"
  tags = {
    Name = "NATgw"
  }

}

resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.terra.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags = {
    Name = "newgateway"
  }
}

resource "aws_route_table" "r2" {
  vpc_id = "${aws_vpc.terra.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.gw1.id}"
  }
  tags = {
    Name = "natgateway"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main2.id
  route_table_id = aws_route_table.r2.id
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.main1.id
  route_table_id = aws_route_table.r.id
}

resource "aws_security_group" "ServiceSG3" {
  name        = "ServiceSG3"
  description = "Security for allowing ssh and 80"
  vpc_id      = "${aws_vpc.terra.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "ServiceSG" {
  name        = "ServiceSG"
  description = "Security for allowing ssh and 80"
  vpc_id      = "${aws_vpc.terra.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
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
resource "aws_security_group" "ServiceSG1" {
  name        = "ServiceSG1"
  description = "Security for allowing ssh and 80"
  vpc_id      = "${aws_vpc.terra.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = ["${aws_security_group.ServiceSG.id}"]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
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
resource "aws_instance" "myin" {
 ami            ="ami-0447a12f28fddb066"
 instance_type  = "t2.micro"
 availability_zone = "ap-south-1a"
 key_name       = "webserver"
 vpc_security_group_ids = ["${aws_security_group.ServiceSG.id}"]
 subnet_id= "${aws_subnet.main1.id}"
 
 tags = {
    Name = "Bastion Host"
 }
}
resource "aws_instance" "myin2" {
 ami            ="ami-0447a12f28fddb066"
 instance_type  = "t2.micro"
 availability_zone = "ap-south-1a"
 key_name       = "webserver"
 vpc_security_group_ids = ["${aws_security_group.ServiceSG3.id}"]
 subnet_id= "${aws_subnet.main1.id}"
 
 tags = {
    Name = "Wordpress"
 }
}

resource "aws_instance" "myin1" {
 ami            ="ami-0447a12f28fddb066"
 instance_type  = "t2.micro"
 availability_zone = "ap-south-1a"
 key_name       = "webserver"
 vpc_security_group_ids = ["${aws_security_group.ServiceSG1.id}"]
 subnet_id= "${aws_subnet.main2.id}"
 
 tags = {
    Name = "Database"
 }
}
