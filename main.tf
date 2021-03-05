provider "aws" {
	region = "ap-northeast-2"
}

data "aws_availability_zones" "available" {
	state = "available"
}

data "aws_acm_certificate" "acm_cert"   {
  domain   = "*.beyonddevops.net"
  statuses = ["ISSUED"]
}


#resource "aws_instance" "example" {
#	ami	= "ami-006e2f9fa7597680a"
#	instance_type = "t2.micro"
#	vpc_security_group_ids = [aws_security_group.instance.id]
#	
#	# EC2 인스턴스의 user_data 설정을 통해 여러 줄의 스크립트 처리
#	# <<-EOF, EOF는 새로운 줄에 문자를 매번 추가하는 것이 아니라 
# 	# 여러 줄의 단락으로 처리하는 테라폼의 heredoc 문법
#	user_data = <<-EOF
#				#!/bin/bash
#				echo "Hello, World" > index.html
#				nohup busybox httpd -f -p var.server_port &
#				EOF
#
#	tags = {
#		Name = "terraform-example"
#	}
#}

resource "aws_security_group" "instance" {
	name = "terraform-example-instance"

	ingress {
		from_port = 8080
		to_port = 8080
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	# 해당 인스턴스를 삭제하기 전에 새로운 인스턴스를 생성한다
	lifecycle {
		create_before_destroy = true
	}
}

resource "aws_security_group" "elb" {
	name = "terraform-example-elb"

	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	
	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_launch_configuration" "example" {
	image_id	= "ami-006e2f9fa7597680a"
	instance_type = "t2.micro"
	security_groups = [ aws_security_group.instance.id ]

	# EC2 인스턴스의 user_data 설정을 통해 여러 줄의 스크립트 처리
	# <<-EOF, EOF는 새로운 줄에 문자를 매번 추가하는 것이 아니라 
	# 여러 줄의 단락으로 처리하는 테라폼의 heredoc 문법
	user_data = <<-EOF
				#!/bin/bash
				echo "Hello, World" > index.html
				nohup busybox httpd -f -p var.server_port &
				EOF

	lifecycle {
		create_before_destroy = true
	}
}

resource "aws_autoscaling_group" "example" {
	launch_configuration = aws_launch_configuration.example.id
	availability_zones = [ data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1] ]	
	# availability_zones = [ data.aws_availability_zones.available.names ]

	load_balancers = [ aws_elb.example.name ]
	health_check_type = "ELB"

	desired_capacity = 2
	min_size = 2
	max_size = 10

	tag {
		key = "Name"
		value = "terraform-asg-example"
		propagate_at_launch = true
	}
}

resource "aws_alb" "example" {
  name            = "terraform-alb-example"
  load_balancer_type = "application"
  idle_timeout       = 3600
  security_groups = [ aws_security_group.elb.id ]
  # aws_subnet_ids.<subnet-name>.id를 하면 subnet ID에 vpc ID가 들어감
  subnets = data.aws_subnet_ids.ga_alb-subnets.ids
}

## alb_listener
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_alb.example.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.acm_cert.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

#resource "aws_elb" "example" {
#	name = "terraform-elb-example"
#	availability_zones = [ data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
#	security_groups = [ aws_security_group.elb.id ]
#
#	listener {
#		lb_port = 80
#		lb_protocol = "http"
#		instance_port = var.server_port
#		instance_protocol = "http"
#	}
#
#	health_check {
#		healthy_threshold = 2
#		unhealthy_threshold = 2
#		timeout = 3
#		interval = 30
#		target = "HTTP:${var.server_port}/"
#	}
#}
