variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "user_names" {
	description = "Create IAM users with these names"
	type = list
	default = ["jhlim", "tjhwang", "espark", "dhlim"]
}

variable "iam_poilcies" {
	description = "IAM policies for devops user group"
	type = list
	default = [ "arn:aws:iam::aws:policy/AmazonRDSFullAccess", "arn:aws:iam::aws:policy/AmazonEC2FullAccess", "arn:aws:iam::aws:policy/iamfullaccess", "arn:aws:iam::aws:policy/AmazonS3FullAccess", "arn:aws:iam::aws:policy/CloudWatchFullAccess", "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess", "arn:aws:iam::aws:policy/AmazonRoute53FullAccess", "arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess"]
}
