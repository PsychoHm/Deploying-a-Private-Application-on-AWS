terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
}

resource "aws_lb" "internal" {
  name               = "my-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.private_subnet_ids

  enable_deletion_protection = false

  access_logs {
    bucket  = var.access_logs_bucket
    enabled = true
  }

  tags = {
    Name = "InternalALB"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "APPTG"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = "/health"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  deregistration_delay = 10

  tags = {
    Name = "AppTG"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}