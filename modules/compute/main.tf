# Security Group for Load Balancer
resource "aws_security_group" "alb" {
  name        = "${var.prefix}-alb-sg"
  vpc_id      = var.vpc_id
  description = "Allow inbound HTTP public traffic"

  ingress {
    from_port   = 80
    to_port     = 80
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

# Security Group for Web Instances
resource "aws_security_group" "web" {
  name        = "${var.prefix}-web-sg"
  vpc_id      = var.vpc_id
  description = "Allow traffic from ALB only"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "web" {
  name               = "${var.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets
}

resource "aws_lb_target_group" "web" {
  name     = "${var.prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    port                = "80"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Auto Scaling Launch Template (Self-Provisioning & Container Pull)
resource "aws_launch_template" "web" {
  name_prefix   = "${var.prefix}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  # Add this line right here:
  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web.id]
  }

  user_data = var.user_data_base64

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group (Self-Healing, N+1 Capacity)
resource "aws_autoscaling_group" "web" {
  name_prefix         = "${var.prefix}-asg-"
  desired_capacity    = 2  # N+1 configuration
  max_size            = 4
  min_size            = 2
  target_group_arns   = [aws_lb_target_group.web.arn]
  vpc_zone_identifier = var.public_subnets

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  # Self-healing via ALB health checks
  health_check_type         = "ELB"
  health_check_grace_period = 120

  lifecycle {
    create_before_destroy = true
  }
}

# Create an IAM Role for the EC2 instances
resource "aws_iam_role" "ssm_role" {
  name = "${var.prefix}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AWS's managed policy for SSM core functionality
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create the instance profile that the Launch Template can ingest
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.prefix}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}
