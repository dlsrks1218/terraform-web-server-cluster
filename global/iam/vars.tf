variable "aws_region" {
  description = "AWS Region"
  default     = "ap-northeast-2"
}


variable "users" {
	description = "Create IAM Users"
	type = list

	default = [ "terraform", "jhlim", "tjhwang", "espark", "dhlim" ]
}
