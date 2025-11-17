# -----------------------------------------------------------------------------
# Network Load Balancer
# -----------------------------------------------------------------------------

# NLB 1 in subnet 0 (AZ1)
resource "aws_lb" "nlb_se1a" {
  name               = "nlb-se1a"
  internal           = true
  load_balancer_type = "network"
  security_groups    = [aws_security_group.nlb_sg.id]

  # Attach to first subnet
  subnet_mapping {
    subnet_id  = var.subnet_mapping["nlb-se1a"].subnet_id
    private_ipv4_address = var.subnet_mapping["nlb-se1a"].private_ip
  }

  enable_deletion_protection = false
  tags = { Name = "nlb-se1a" }
}

# NLB 2 in subnet 1 (AZ2)
resource "aws_lb" "nlb_se1b" {
  name               = "nlb-se1b"
  internal           = true
  load_balancer_type = "network"
  security_groups    = [aws_security_group.nlb_sg.id]

  # Attach to second subnet
  subnet_mapping {
    subnet_id  = var.subnet_mapping["nlb-se1b"].subnet_id
    private_ipv4_address = var.subnet_mapping["nlb-se1b"].private_ip
  }

  enable_deletion_protection = false
  tags = { Name = "nlb-se1b" }
}

resource "aws_security_group" "nlb_sg" {
  name        = "nlb-shared-sg"
  description = "Security group for both NLBs"
  vpc_id      = var.vpc_id

  # Allow inbound from the internet or your CIDR
  ingress {
    description = "Allow inbound to NLB (HTTP)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound to NLB (HTTPS)"
    from_port   = 443
    to_port     = 443
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

resource "aws_security_group_rule" "allow_nlb_to_nodes" {
  type                     = "ingress"
  from_port                = 31730
  to_port                  = 31730
  protocol                 = "tcp"
  security_group_id        = var.eks_nodes_sg_id
  source_security_group_id = aws_security_group.nlb_sg.id
  #cidr_blocks       = [aws_vpc.main.cidr_block]
  description              = "Allow traffic from both NLBs to NodePort"
}

resource "aws_lb_target_group" "nginx_tg_se1a" {
  name        = "nginx-tg-se1a"
  port        = 31730
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
    port     = "31730"
    protocol = "TCP"
  }
}

resource "aws_lb_target_group" "nginx_tg_se1b" {
  name        = "nginx-tg-se1b"
  port        = 31730
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
    port     = "31730"
    protocol = "TCP"
  }
}

resource "aws_lb_listener" "az1_listener" {
  load_balancer_arn = aws_lb.nlb_se1a.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_tg_se1a.arn
  }
}

resource "aws_lb_listener" "az2_listener" {
  load_balancer_arn = aws_lb.nlb_se1b.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_tg_se1b.arn
  }
}

resource "aws_lb_target_group_attachment" "nginx_nodeport_se1a" {
  count            = length(data.aws_instances.eks_nodes.ids)
  target_group_arn = aws_lb_target_group.nginx_tg_se1a.arn
  target_id        = data.aws_instances.eks_nodes.ids[count.index]  # instance IDs
  port             = 31730
}

resource "aws_lb_target_group_attachment" "nginx_nodeport_se1b" {
  count            = length(data.aws_instances.eks_nodes.ids)
  target_group_arn = aws_lb_target_group.nginx_tg_se1b.arn
  target_id        = data.aws_instances.eks_nodes.ids[count.index]  # instance IDs
  port             = 31730
}

data "aws_instances" "eks_nodes" {
  instance_tags = {
    "kubernetes.io/cluster/biocenter-cluster" = "owned"
  }
}