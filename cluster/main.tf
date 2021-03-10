provider "aws" {
	region = var.aws_region 
	shared_credentials_file = "/Users/jonghyunlim/.aws/credentials"
	profile = "dlsrks1218"
}

data "aws_availability_zones" "available" {
	state = "available"
}

# 기존의 호스팅 영역을 사용하기 위해서
# plan 전에 terraform import aws_route53_zone.primary <<기존의 zone id>> 로 임포트하기
# terraform import aws_route53_zone.primary Z00229973JA10VRIVA0W
resource "aws_route53_zone" "primary" {
  name = "beyonddevops.net"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.beyonddevops.net"
  type    = "A"

  alias {
    name                   = aws_alb.example.dns_name
    zone_id                = aws_alb.example.zone_id
    evaluate_target_health = true
  }
#	tags = {
#		Environment = "dev"
#	}
}

data "aws_acm_certificate" "acm_cert"   {
  domain   = "beyonddevops.net"
  statuses = ["ISSUED"]
}

data "aws_subnet_ids" "alb-subnets" {
  vpc_id = var.vpc_id
}

resource "aws_security_group" "alb" {
	name = "terraform-example-alb"

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_security_group_rule" "http" {
	security_group_id = aws_security_group.alb.id 

	type = "ingress"
	from_port = 80 
	to_port = 80 
	protocol = "tcp" 
	cidr_blocks = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "https" {
	security_group_id = aws_security_group.alb.id 
	
	type = "ingress"
	from_port = 443 
	to_port = 443
	protocol = "tcp" 
	cidr_blocks = ["0.0.0.0/0"]
}

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

resource "aws_launch_configuration" "example" {
	image_id	= "ami-006e2f9fa7597680a"
	instance_type = "t2.micro"
	security_groups = [ aws_security_group.instance.id ]
	# security_groups = [ aws_security_group.alb.id ]

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
	availability_zones = [ data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2],  data.aws_availability_zones.available.names[3] ]	
	# availability_zones = [ data.aws_availability_zones.available.names ]

	# load_balancers = [ aws_alb.example.name ]
	health_check_type = "ELB"

	desired_capacity = 2
	min_size = 2
	max_size = 10

	# ASG에 의해 생성된 인스턴스들을 target_group으로 추가시키기 위해 ASG 리소스에 target_group_arn 추가함
	# aws_autoscaling_attacment, aws_target_group_attachment는 무쓸모
	target_group_arns = [ aws_alb_target_group.test.arn ]

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
  security_groups = [ aws_security_group.alb.id ]
  subnets = data.aws_subnet_ids.alb-subnets.ids
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

## alb_listener 규칙 - 대상은 테스트용 TG 2개
resource "aws_alb_listener_rule" "https_listener_www" {
  listener_arn = aws_alb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.test.arn
  }

  condition {
    host_header {
      values = ["www.beyonddevops.net"]
    }
  }
}

resource "aws_alb_target_group" "test" {
	name = "test-target-group"
	port = 80
	protocol = "HTTP"
	vpc_id = var.vpc_id

	health_check {
		interval = 30
		path = "/"
		healthy_threshold = 3
		unhealthy_threshold = 3
	}
	
	tags = {
		Name = "test"
	}
}


######################################################################

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
#resource "aws_security_group" "instance" {
#	name = "terraform-example-instance"
#
#	ingress {
#		from_port = 8080
#		to_port = 8080
#		protocol = "tcp"
#		cidr_blocks = ["0.0.0.0/0"]
#	}
#	# 해당 인스턴스를 삭제하기 전에 새로운 인스턴스를 생성한다
#	lifecycle {
#		create_before_destroy = true
#	}
#}
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

