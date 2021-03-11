provider "aws" {
	region = var.aws_region 
	shared_credentials_file = "/Users/jonghyunlim/.aws/credentials"
	profile = "dlsrks1218"
}

data "aws_availability_zones" "available" {
	state = "available"
}

data "aws_acm_certificate" "acm_cert"   {
  domain   = "beyonddevops.net"
  statuses = ["ISSUED"]
}

data "aws_subnet_ids" "alb-subnets" {
  vpc_id = var.vpc_id
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

