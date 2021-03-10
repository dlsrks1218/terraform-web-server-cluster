output "all_users_arn" {
	value = aws_iam_user.devops_user.*.arn
}
