output "bastion_host_public_ip" {
	description = "contains the public IP address"
	value = aws_eip.my_vpc_bastion.public_ip
}

output "key_name" {
	description = "key name for bastion host"
	value = aws_instance.my_vpc_bastion.key_name 
}
