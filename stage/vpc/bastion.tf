// Basiton Host
resource "aws_security_group" "my_vpc_bastion" {
  name = "bastion"
  description = "Security group for bastion instance"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion"
  }
}

resource "aws_instance" "my_vpc_bastion" {
  # ami = "ami-0e17ad9abf7e5c818"
  ami = var.ami_id 
  
  availability_zone = aws_subnet.my_vpc_public_subnet01.availability_zone
  instance_type = "t2.nano"
  key_name = "ec2-test01"
  vpc_security_group_ids = [
    aws_default_security_group.my_vpc_default.id,
    aws_security_group.my_vpc_bastion.id
  ]
  subnet_id = aws_subnet.my_vpc_public_subnet01.id
  associate_public_ip_address = true

  tags = {
    Name = "bastion"
  }
}

resource "aws_eip" "my_vpc_bastion" {
  vpc = true
  instance = aws_instance.my_vpc_bastion.id
  depends_on = [ aws_internet_gateway.my_vpc_igw ]
}
