# -----------------------------------------------------------------------------
# Security Group for Bastion Host
# -----------------------------------------------------------------------------

resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name   = "${var.name}-sg"
      Module = "bastion"
    }
  )
}

# -----------------------------------------------------------------------------
# EC2 Key Pair
# -----------------------------------------------------------------------------

resource "aws_key_pair" "this" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = var.key_name
  public_key = var.public_key
}

# -----------------------------------------------------------------------------
# EC2 Bastion Instance
# -----------------------------------------------------------------------------

resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  key_name                    = var.create_key_pair ? aws_key_pair.this[0].key_name : var.key_name
  associate_public_ip_address = true
  monitoring                  = false

  user_data = var.user_data

  tags = merge(
    var.tags,
    {
      Name   = var.name
      Module = "bastion"
    }
  )
}

# -----------------------------------------------------------------------------
# Optional EIP (for static SSH access)
# -----------------------------------------------------------------------------

resource "aws_eip" "this" {
  count    = var.create_eip ? 1 : 0
  instance = aws_instance.this.id
  vpc      = true

  tags = merge(
    var.tags,
    {
      Name   = "${var.name}-eip"
      Module = "bastion"
    }
  )
}
