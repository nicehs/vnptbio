
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# resource "aws_iam_role" "ssm_role" {
#   name = "license-server-ssm-role"
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

# resource "aws_iam_role_policy_attachment" "license_server_custom_eks_access" {
#   role       = aws_iam_role.license_server_ssm_role.name
#   policy_arn = "arn:aws:iam::136079915181:policy/EKSPlayground"
# }

# resource "aws_instance" "license-server" {
#   ami                  = data.aws_ami.amazon_linux.id
#   instance_type        = "t3.micro"
#   subnet_id            = var.subnet_id
#   vpc_security_group_ids      = [aws_security_group.license_server_sg.id]
#   iam_instance_profile = var.license_server_ssm_profile_name
#   tags                 = { Name = "license-server" }
#   private_ip = "10.233.8.186"
#   user_data = <<-EOF
#     #!/bin/bash
#     set -e
#     exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

#     echo "Starting SSM agent setup..." >> /var/log/user-data.log
#     systemctl enable amazon-ssm-agent
#     systemctl start amazon-ssm-agent
#     echo "SSM agent enabled and started" >> /var/log/user-data.log
#     systemctl status amazon-ssm-agent >> /var/log/user-data.log

#     # Update packages
#     yum update -y || apt-get update -y

#     # Install dependencies
#     yum install -y unzip curl || apt-get install -y unzip curl
#   EOF

#   # lifecycle {
#   #   prevent_destroy = true  # Terraform won't destroy this resource
#   # }

#   #depends_on = [aws_eks_cluster.vnpt_cluster]
#   depends_on = [var.aws_eks_cluster_vnpt_cluster]
# }

resource "aws_security_group" "license_server_sg" {
  name        = "license-server-sg"
  description = "Security group for license server (SSM only)"
  vpc_id      = var.vpc_id

  ingress {
    description = "Alow connect to license server for managing license"
    from_port   = 8002
    to_port     = 8002
    protocol    = "tcp"
    cidr_blocks = ["10.233.8.0/24","100.64.0.0/16"]
  }

  ingress {
    description = "Alow ssh access to license server"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.233.8.0/24","100.64.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "license-server-sg" }
}

# resource "aws_instance" "database_server" {
#   ami                  = data.aws_ami.amazon_linux.id
#   instance_type        = "t2.xlarge"
#   subnet_id            = var.subnet_id
#   vpc_security_group_ids      = [aws_security_group.database_server_sg.id]
#   private_ip           = "10.233.8.199"
#   tags                 = { Name = "database-server" }
#   # lifecycle {
#   #   prevent_destroy = true  # Terraform won't destroy this resource
#   # }
# }

resource "aws_security_group" "database_server_sg" {
  name        = "database-server-sg"
  description = "Security group for license server"
  vpc_id      = var.vpc_id

  ingress {
    description = "Alow ssh access to database server"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "database-server-sg" }
}

# # 3 volumes 50GB
# resource "aws_ebs_volume" "data_50" {
#   count             = 3
#   availability_zone = "ap-southeast-1b"
#   size              = 50
#   type              = "gp3"

#   tags = {
#     Name = "database-server-volume-50gb-${count.index + 1}"
#   }
# }

# # 1 volume 100GB
# resource "aws_ebs_volume" "data_100" {
#   availability_zone = "ap-southeast-1b"
#   size              = 100
#   type              = "gp3"

#   tags = {
#     Name = "database-server-volume-100gb"
#   }
# }

# # Attach 3 x 50GB
# resource "aws_volume_attachment" "attach_50" {
#   count       = 3
#   device_name = "/dev/xvd${element(["b", "c", "d"], count.index)}"
#   volume_id   = aws_ebs_volume.data_50[count.index].id
#   instance_id = aws_instance.database_server.id
# }

# # Attach 1 x 100GB
# resource "aws_volume_attachment" "attach_100" {
#   device_name = "/dev/xvde"
#   volume_id   = aws_ebs_volume.data_100.id
#   instance_id = aws_instance.database_server.id
# }