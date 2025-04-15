# IF you want to use your own IP address & Production-Ready Please use this!
# data "http" "myip" {
#   url = "http://ipv4.icanhazip.com"
# }
# cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]

# alb_sg
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow HTTPS from your IP only"
  vpc_id      = aws_vpc.core_vpc.id

  ingress {
    description = "Allow HTTP from your IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# bastion_sg
resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "Allow specific inbound and all outbound traffic"
  vpc_id      = aws_vpc.core_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# jenkins_sg
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Allow specific inbound and all outbound traffic"
  vpc_id      = aws_vpc.core_vpc.id

  ingress {
    description     = "Allow traffic from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# eks_sg
resource "aws_security_group" "eks_sg" {
  name        = "eks_sg"
  description = "Allow specific inbound and all outbound traffic"
  vpc_id      = aws_vpc.core_vpc.id

  ingress {
    description     = "Allow port 30000-32767 from jenkins_sg"
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# monitor_sg
resource "aws_security_group" "monitor_sg" {
  name        = "monitor_sg"
  description = "Allow specific inbound and all outbound traffic"
  vpc_id      = aws_vpc.core_vpc.id

  ingress {
    description = "Allow port 9090 from my IP"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Allow port 9090 from eks_sg"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# sonartriny_sg
resource "aws_security_group" "sonartriny_sg" {
  name        = "sonartriny_sg"
  description = "Allow specific inbound and all outbound traffic"
  vpc_id      = aws_vpc.core_vpc.id

  ingress {
    description = "Allow port 9000 from my IP"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Allow port 9000 from jenkins_sg"
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}