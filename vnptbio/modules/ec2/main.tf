
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# resource "aws_iam_role" "ssm_role" {
#   name = "bastion-ssm-role"
#   assume_role_policy = data.aws_iam_policy_document.ssm_assume_role_policy.json
# }

data "aws_iam_policy_document" "ssm_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# resource "aws_iam_role_policy_attachment" "bastion_custom_eks_access" {
#   role       = aws_iam_role.bastion_ssm_role.name
#   policy_arn = "arn:aws:iam::136079915181:policy/EKSPlayground"
# }

resource "aws_instance" "bastion" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = "t3.micro"
  subnet_id            = var.subnet_id
  security_groups      = [aws_security_group.bastion_sg.id]
  iam_instance_profile = var.bastion_ssm_profile_name
  tags                 = { Name = "bastion-host" }
  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

    echo "Starting SSM agent setup..." >> /var/log/user-data.log
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    echo "SSM agent enabled and started" >> /var/log/user-data.log
    systemctl status amazon-ssm-agent >> /var/log/user-data.log

    # Update packages
    yum update -y || apt-get update -y

    # Install dependencies
    yum install -y unzip curl || apt-get install -y unzip curl

    # Install kubectl
    #KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/v1.34.1/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/bin/kubectl
    rm kubectl

    # Install AWS CLI v2
    yum remove awscli -y
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install --bin-dir /usr/bin --install-dir /usr/local/aws-cli

    # Update the package repository
    sudo yum update -y

    # Install Docker
    sudo yum install -y docker

    # Start Docker service
    sudo systemctl start docker

    # Enable Docker to start on boot
    sudo systemctl enable docker

    # Download the latest Helm binary (for Linux AMD64)
    curl -LO https://get.helm.sh/helm-v3.12.3-linux-amd64.tar.gz
    tar -zxvf helm-v3.12.3-linux-amd64.tar.gz
    sudo mv linux-amd64/helm /usr/bin/helm
    sudo chmod +x /usr/bin/helm
    helm version

    # Install eksctl
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" -o eksctl.tar.gz
    tar -xzf eksctl.tar.gz
    sudo mv eksctl /usr/bin/eksctl
    sudo chmod +x /usr/bin/eksctl
    eksctl version

    # Add kube config
    sudo aws eks --region ap-southeast-1 update-kubeconfig --name biocenter-cluster

    # Install registry
    sudo helm repo add twuni https://helm.twun.io
    sudo helm repo update
    sudo kubectl create serviceaccount registry-sa --namespace default
    sudo kubectl annotate serviceaccount registry-sa   eks.amazonaws.com/role-arn=arn:aws:iam::136079915181:role/eks-irsa-registry-role   --namespace default
    sudo helm upgrade --install docker-registry twuni/docker-registry   --namespace default   --create-namespace   --set persistence.enabled=false   --set service.type=NodePort   --set service.port=5000  \
    --set storage=s3   --set s3.region=ap-southeast-1   --set s3.bucket=registry-bio1   --set s3.encrypt=true   --set serviceAccount.create=false   --set serviceAccount.name=registry-sa   --set secrets.s3.secretKey=""

    # Install ingress
    sudo helm repo add eks https://aws.github.io/eks-charts
    sudo helm repo update
    sudo kubectl create serviceaccount aws-load-balancer-controller --namespace kube-system
    sudo kubectl annotate serviceaccount aws-load-balancer-controller   -n kube-system   eks.amazonaws.com/role-arn=arn:aws:iam::136079915181:role/eks-load-balancer-controller-role
    VPCID=`sudo aws ec2 describe-vpcs --filters "Name=tag:Name,Values=eks-vpc" --query "Vpcs[0].VpcId" --output text`
    sudo helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller   -n kube-system   --set clusterName=biocenter-cluster   --set serviceAccount.create=false \
      --set region=ap-southeast-1   --set vpcId=$VPCID  --set serviceAccount.name=aws-load-balancer-controller
  EOF

  #depends_on = [aws_eks_cluster.biocenter_cluster]
  depends_on = [var.aws_eks_cluster_biocenter_cluster]
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for bastion host (SSM only)"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "bastion-sg" }
}