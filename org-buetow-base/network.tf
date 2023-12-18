resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16" # Specify your CIDR block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-my-vpc"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.environment}-my-igw"
  }
}

resource "aws_subnet" "my_public_subnet_a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-my-public-subnet-a"
  }
}

resource "aws_subnet" "my_public_subnet_b" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-my-public-subnet-b"
  }
}

resource "aws_subnet" "my_public_subnet_c" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-central-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-my-public-subnet-c"
  }
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "${var.environment}-my-route-table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my_public_subnet_a.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.my_public_subnet_b.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.my_public_subnet_c.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-allow-ssh"
  }
}

resource "aws_security_group" "allow_web" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-allow_web"
  }
}

resource "aws_security_group" "allow_outbound" {
  name        = "allow_outbound"
  description = "Allow outbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"] # Allows outbound traffic to all IP addresses
  }

  tags = {
    Name = "${var.environment}-allow-outbound"
  }
}
