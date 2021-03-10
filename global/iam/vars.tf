variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

#variable "vpc_id" {
#  description = "Workspace VPC ID"
#  # Name : crscube-tokyo-vpc
#  default     = "vpc-053250658d267b1e2"
#}

variable "user_names" {
	description = "Create IAM users with these names"
	type = list
	default = ["jhlim", "tjhwang", "espark", "dhlim"]
}
