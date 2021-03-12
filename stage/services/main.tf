provider "aws" {
	region = var.aws_region 
	shared_credentials_file = "/Users/jonghyunlim/.aws/credentials"
	profile = "dlsrks1218"
}

data "aws_availability_zones" "available" {
	state = "available"
}

data "aws_subnet_ids" "alb-subnets" {
  vpc_id = var.vpc_id
}

data "aws_acm_certificate" "acm_cert"   {
  domain   = "beyonddevops.net"
  statuses = ["ISSUED"]
}


#data "aws_availability_zones" "public_subnets" {
#	state = "available"
#	
#	filter {
#		name = "Name"
#		values = [ "public-az-1", "public-az-2" ]
#	}
#}
#
#data "aws_availability_zones" "private_subnets" {
#	state = "available"
#	
#	filter {
#		name = "Name"
#		values = [ "private-az-1", "private-az-2" ]
#	}
#}

#data "aws_subnet_ids" "public-subnets" {
#  vpc_id = var.vpc_id
#
#
#}

#data "aws_subnet_ids" "private-subnets" {
#  vpc_id = var.vpc_id
#}
