# Create LB for Jenkins
resource "aws_lb" "jenkins_alb" {
  name               = "jenkins-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.public_subnet_ALB[0].id,
    aws_subnet.public_subnet_ALB[1].id
  ]
  tags = {
    Name = "jenkins-alb"
  }
}

resource "aws_lb_target_group" "jenkins_tg" {
  name     = "jenkins-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.core_vpc.id

  health_check {
    path                = "/"
    port                = "8080"
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "jenkins-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.jenkins_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "jenkins_attach" {
  target_group_arn = aws_lb_target_group.jenkins_tg.arn
  target_id        = aws_instance.jenkins-master-ec2.id
  port             = 8080
}

# Create Jenkins Cluster
resource "aws_instance" "jenkins-master-ec2" {
  ami                         = "ami-0c1907b6d738188e5"
  instance_type               = "t2.micro"
  key_name                    = "terraform-key"
  subnet_id                   = aws_subnet.private_subnet[0].id
  associate_public_ip_address = false
  user_data                   = file("scripts/ubnutu/install-jenkins-master.sh")
  root_block_device {
    volume_size = 30
  }
  tags = {
    Name = "jenkins-master-ec2"
  }
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
}

resource "aws_instance" "jenkins-agent-node1-ec2" {
  ami                         = "ami-0c1907b6d738188e5"
  instance_type               = "t2.micro"
  key_name                    = "terraform-key"
  subnet_id                   = aws_subnet.private_subnet[1].id
  user_data                   = file("scripts/ubnutu/install-jenkins-agent.sh")
  associate_public_ip_address = false
  root_block_device {
    volume_size = 30
  }
  tags = {
    Name = "jenkins-agent-node1-ec2"
  }
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
}

# Create Bastion Instance
resource "aws_instance" "jenkins-bastion-ec2" {
  ami                         = "ami-065a492fef70f84b1"
  instance_type               = "t2.micro"
  key_name                    = "terraform-key"
  subnet_id                   = aws_subnet.public_subnet_Bastion.id
  associate_public_ip_address = true
  root_block_device {
    volume_size = 30
  }
  tags = {
    Name = "jenkins-bastion-ec2"
  }
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
}

# Create S3 bucket for Jenksin Artifacts
resource "aws_s3_bucket" "jenkins_s3_bucket" {
  bucket = "kailop-jenkins-artifacts"

  tags = {
    Name = "Jenkins-Server"
  }
}

resource "aws_s3_bucket_acl" "s3_bucket_acl" {
  bucket     = aws_s3_bucket.jenkins_s3_bucket.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.jenkins_s3_bucket_ownership]
}

resource "aws_s3_bucket_ownership_controls" "jenkins_s3_bucket_ownership" {
  bucket = aws_s3_bucket.jenkins_s3_bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}