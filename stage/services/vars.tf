variable "aws_region" {
  description = "AWS Region"
  default     = "ap-northeast-2"
}

variable "vpc_id" {
	description = "VPC ID"
	default = "vpc-0dc879d38ac329c6d"
}

variable "server_port" {
	description = "Port for HTTP requests"
	type = string
	default = 8080
}
