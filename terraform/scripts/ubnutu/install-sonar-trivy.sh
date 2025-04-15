#!/bin/bash
# Installing Docker on Amazon Linux 2
sudo yum update -y
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker jenkins
sudo usermod -aG docker ec2-user
sudo chmod 777 /var/run/docker.sock

# Run Docker Container of SonarQube
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community

# Installing Trivy on Amazon Linux 2
sudo rpm --import https://aquasecurity.github.io/trivy-repo/rpm/public.key
sudo curl -o /etc/yum.repos.d/trivy.repo https://aquasecurity.github.io/trivy-repo/rpm/releases/$(rpm -E %{rhel})/trivy.repo
sudo yum install trivy -y
trivy --version