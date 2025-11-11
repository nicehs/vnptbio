# -----------------------------------------------------------------------------
# Network Load Balancer
# -----------------------------------------------------------------------------

resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "network"
  subnets            = var.subnets
  enable_deletion_protection = var.enable_deletion_protection

  tags = merge(
    var.tags,
    {
      Name   = var.name
      Module = "nlb"
    }
  )
}

# -----------------------------------------------------------------------------
# Target Group(s)
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "this" {
  name        = var.target_group_name
  port        = var.target_port
  protocol    = var.target_protocol
  vpc_id      = var.vpc_id
  target_type = var.target_type
  health_check {
    enabled             = var.health_check_enabled
    interval            = var.health_check_interval
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = var.health_check_protocol
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
  }

  tags = merge(
    var.tags,
    {
      Name   = var.target_group_name
      Module = "nlb"
    }
  )
}

# -----------------------------------------------------------------------------
# Listener(s)
# -----------------------------------------------------------------------------

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# -----------------------------------------------------------------------------
# Optional Target Attachment (e.g. EC2s or IPs)
# -----------------------------------------------------------------------------

resource "aws_lb_target_group_attachment" "this" {
  for_each = var.target_attachments
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = each.value.target_id
  port             = each.value.port
}
