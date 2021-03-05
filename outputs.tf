#output "public_ip" {
#  description = "List of public IP addresses assigned to the instances, if applicable"
#  value       = aws_instance.example.public_ip
#}

#output "public_ips" {
#	description = "List of public IP addresses assigned to the instances, if applicable"
#	value = aws_
#}

output "elb_dns_name" {
	value = aws_alb.example.dns_name
}
