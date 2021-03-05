variable "aws_region" {
  description = "AWS Region"
  default     = "ap-northeast-2"
}

variable "server_port" {
	description = "Port for HTTP requests"
	type = string
	default = 8080
}
