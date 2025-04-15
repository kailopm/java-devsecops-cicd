# Create a VPC
resource "aws_vpc" "core_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private_subnet" {
  count      = 5
  vpc_id     = aws_vpc.core_vpc.id
  cidr_block = "10.0.${count.index + 1}.0/24"

  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

# Create public subnets for NAT Gateway
resource "aws_subnet" "public_subnet_NAT" {
  vpc_id                  = aws_vpc.core_vpc.id
  cidr_block              = "10.0.${length(aws_subnet.private_subnet) + 1}.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-NAT-gw"
  }
}

# Create public subnets for bastion host
resource "aws_subnet" "public_subnet_Bastion" {
  vpc_id                  = aws_vpc.core_vpc.id
  cidr_block              = "10.0.${length(aws_subnet.public_subnet_NAT) + 1}.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-bastion"
  }
}

# Create public subnets for ALB
resource "aws_subnet" "public_subnet_ALB" {
  count                   = 2
  vpc_id                  = aws_vpc.core_vpc.id
  cidr_block              = "10.0.${count.index + length(aws_subnet.private_subnet) + 10}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = element(["ap-southeast-1a", "ap-southeast-1b"], count.index)
  tags = {
    Name = "public-subnet-ALB-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.core_vpc.id
  tags = {
    Name = "Internet-gw"
  }
}

resource "aws_eip" "nat_gateway_ip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_gateway_ip.id
  subnet_id     = aws_subnet.public_subnet_NAT.id
  tags = {
    Name = "NAT-gw"
  }
  depends_on = [aws_internet_gateway.main]
}

# Create route table for private subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.core_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "Public-RT"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.core_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "Private-RT"
  }
}

# Associate route table (Public)
resource "aws_route_table_association" "public_nat" {
  subnet_id      = aws_subnet.public_subnet_NAT.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_bastion" {
  subnet_id      = aws_subnet.public_subnet_Bastion.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_alb" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet_ALB[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Associate route table (Private)
resource "aws_route_table_association" "private_subnets" {
  count          = 5
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}