resource "aws_autoscaling_group" "app" {
  launch_configuration = aws_launch_configuration.app.id
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = var.subnet_ids

  tags = [
    {
      key                 = "Name"
      value               = "app-asg"
      propagate_at_launch = true
    }
  ]
}

resource "aws_launch_configuration" "app" {
  image_id        = var.ami_id
  instance_type   = var.instance_type
  security_groups = var.security_group_ids

  user_data = <<-EOF
    #!/bin/bash
    yum install -y java-1.8.0
    wget http://tomcat.apache.org/tomcat-8.0.36.tar.gz
    tar -xzf tomcat-8.0.36.tar.gz
    ./tomcat-8.0.36/bin/startup.sh
  EOF
}

resource "aws_lb" "app" {
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [var.lb_security_group_id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_target_group" "app" {
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

