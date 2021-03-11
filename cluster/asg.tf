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
