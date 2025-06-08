provider "aws"{
    region = var.region_name
}
resource "aws_security_group" "aws_sg" {
    name = "Jenkins_sg"
    description = "jenkins ser port"

    #port 22 
    ingress{
        description ="ssh port"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    #port 80 
    ingress{
        description ="http port"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
#port 443
    ingress{
        description ="https port"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
#port 8080 
    ingress{
        description ="jenkins port"
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    #port 9000
    ingress{
        description ="sonarqube port"
        from_port = 9000
        to_port = 9000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    #port 9090
    ingress{
        description ="prometheus port"
        from_port = 9090
        to_port = 9090
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    #port 3000
    ingress{
        description ="grafana port"
        from_port = 3000
        to_port = 3000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    #port 2379
    ingress{
        description ="etcd-cluster port"
        from_port = 2379
        to_port = 2379
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    #port 6443
    ingress{
        description ="kube api port"
        from_port = 6443
        to_port = 6443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    #port 9100
    ingress{
        description ="prometheus_metric port"
        from_port = 9100
        to_port = 9100
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    #port 10250
    ingress{
        description ="kubernetes port"
        from_port = 10250
        to_port = 10250
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    #port 30000-32767
    ingress{
        description ="nodeport port"
        from_port = 30000
        to_port = 32767
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks =["0.0.0.0/0"]

    }

}
#crete ec2
resource "aws_instance" "my_ec2"{
    ami  = var.ami
    instance_type = var.instance_type
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.aws_sg.id]
    tags = {
        Name =var.server_name
    }
    root_block_device {
        volume_size =var.volume_size

    }
    provisioner "remote-exec"{
        connection{
            type ="ssh"
            private_key =file("./newcicd.pem")
            user ="ubuntu"
            host =self.public_ip
        }
        inline=[
                #install aws cli
                "sudo apt install unzip -y",
                "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'",
                "unzip awscliv2.zip",
                "sudo ./aws/install",

            
                 # Install Docker
                 # Ref: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
                "sudo apt-get update -y",
                "sudo apt-get install -y ca-certificates curl",
                "sudo install -m 0755 -d /etc/apt/keyrings",
                "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc",
                "sudo chmod a+r /etc/apt/keyrings/docker.asc",
                "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
                "sudo apt-get update -y",
                "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
                "sudo usermod -aG docker ubuntu",
                "sudo chmod 777 /var/run/docker.sock",
                "docker --version",

                 # Install SonarQube (as container)
                "docker run -d --name sonar -p 9000:9000 sonarqube:lts-community",

                # Install Trivy
                # Ref: https://aquasecurity.github.io/trivy/v0.18.3/installation/
                "sudo apt-get install -y wget apt-transport-https gnupg",
                "wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null",
                "echo 'deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main' | sudo tee -a /etc/apt/sources.list.d/trivy.list",
                "sudo apt-get update -y",
                "sudo apt-get install trivy -y",

                # Install Kubectl
                # Ref: https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html#kubectl-install-update
                "curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.4/2024-09-11/bin/linux/amd64/kubectl",
                "curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.4/2024-09-11/bin/linux/amd64/kubectl.sha256",
                "sha256sum -c kubectl.sha256",
                "openssl sha1 -sha256 kubectl",
                "chmod +x ./kubectl",
                "mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH",
                "echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc",
                "sudo mv $HOME/bin/kubectl /usr/local/bin/kubectl",
                "sudo chmod +x /usr/local/bin/kubectl",
                "kubectl version --client",

                 # Install Helm
                # Ref: https://helm.sh/docs/intro/install/
                # Ref (for .tar.gz file): https://github.com/helm/helm/releases
                "wget https://get.helm.sh/helm-v3.16.1-linux-amd64.tar.gz",
                "tar -zxvf helm-v3.16.1-linux-amd64.tar.gz",
                "sudo mv linux-amd64/helm /usr/local/bin/helm",
                "helm version",

                # Install ArgoCD
                # Ref: https://argo-cd.readthedocs.io/en/stable/cli_installation/
                "VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)",
                "curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v$VERSION/argocd-linux-amd64",
                "sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd",
                "rm argocd-linux-amd64",

                 # Install Java 17
                # Ref: https://www.rosehosting.com/blog/how-to-install-java-17-lts-on-ubuntu-20-04/
                "sudo apt update -y",
                "sudo apt install openjdk-17-jdk openjdk-17-jre -y",
                "java -version",

                # Install Jenkins
                # Ref: https://www.jenkins.io/doc/book/installing/linux/#debianubuntu
                "sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key",
                "echo \"deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/\" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",
                "sudo apt-get update -y",
                "sudo apt-get install -y jenkins",
                "sudo systemctl start jenkins",
                "sudo systemctl enable jenkins",

                 # Get Jenkins initial login password
                "ip=$(curl -s ifconfig.me)",
                "pass=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)",

                # Output
                "echo 'Access Jenkins Server here --> http://'$ip':8080'",
                "echo 'Jenkins Initial Password: '$pass''",
                "echo 'Access SonarQube Server here --> http://'$ip':9000'",
                "echo 'SonarQube Username & Password: admin'",

        ]
    }
}
output "SERVER-SSH-ACCESS"{
    value = "ubuntu@${aws_instance.my_ec2.public_ip}"
}
output "PUBLIC-IP"{
    value = "${aws_instance.my_ec2.public_ip}"
}
output "PRIVATE-IP"{
    value = "${aws_instance.my_ec2.private_ip}"
}

