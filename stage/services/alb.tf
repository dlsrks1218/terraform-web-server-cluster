########################################

############   Route 53   ##############

########################################


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
}


########################################

############  Security Group   #########

########################################

resource "aws_security_group" "alb" {
	name = "terraform-example-elb"

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


########################################

###############   ALB  #################

########################################

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
