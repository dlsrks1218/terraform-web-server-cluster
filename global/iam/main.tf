provider "aws" {
  region = var.aws_region
}

resource "aws_iam_group" "devops" {
	name = "devops"
	path = "/users/"
}

resource "aws_iam_group_policy_attachment" "policy_attach" {
	group = "aws_iam_group.devops.name"

# 	policy_arn = [ "arn:aws:iam::aws:policy/AmazonRDSFullAccess", "arn:aws:iam::aws:policy/AmazonEC2FullAccess", "arn:aws:iam::aws:policy/IAMFullAccess", "arn:aws:iam::aws:policy/AmazonS3FullAccess", "arn:aws:iam::aws:policy/CloudWatchFullAccess", "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess", "arn:aws:iam::aws:policy/AmazonRoute53FullAccess", "arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess"]

	policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_iam_user" "devops_user" {
	count = length(var.users)
	name = element(var.users, count.index)
	path = "/devops/"

	tags = {
		Name = "devops_users"
	}
}


resource "aws_iam_user_group_membership" "grp_mem" {
	count = length(var.users)
	user = element(var.users, count.index)
	groups = [
		aws_iam_group.devops.name
	]
}
