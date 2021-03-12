// vpc
resource "aws_vpc" "my_vpc" {
  cidr_block  = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  instance_tenancy = "default"

  tags = {
		Name = "my_vpc"
	}
}

resource "aws_default_route_table" "my_vpc" {
	default_route_table_id = aws_vpc.my_vpc.default_route_table_id

	tags = {
		Name = "public"
	}
}

// Declare the data source
data "aws_availability_zones" "available" {
  state = "available"
}

// public_subnet
resource "aws_subnet" "my_vpc_public_subnet01" {
	vpc_id = aws_vpc.my_vpc.id
	cidr_block = "10.10.1.0/24"
	map_public_ip_on_launch = false 
	availability_zone = data.aws_availability_zones.available.names[0] 
	
	tags = {
		Name = "public-az-1"
	}
}

resource "aws_subnet" "my_vpc_public_subnet02" {
	vpc_id = aws_vpc.my_vpc.id
	cidr_block = "10.10.2.0/24"
	map_public_ip_on_launch = true
	availability_zone = data.aws_availability_zones.available.names[1]
	
	tags = {
		Name = "public-az-2"
	}
}


// private_subnet
resource "aws_subnet" "my_vpc_private_subnet01" {
	vpc_id = aws_vpc.my_vpc.id
	cidr_block = "10.10.11.0/24"
	availability_zone = data.aws_availability_zones.available.names[0]
	
	tags = {
		Name = "private-az-1"
	}
}

resource "aws_subnet" "my_vpc_private_subnet02" {
	vpc_id = aws_vpc.my_vpc.id
	cidr_block = "10.10.12.0/24"
	availability_zone = data.aws_availability_zones.available.names[1]
	
	tags = {
		Name = "private-az-2"
	}
}


// internet gateway
resource "aws_internet_gateway" "my_vpc_igw" {
	vpc_id = aws_vpc.my_vpc.id
	
	tags = {
		Name = "my-internet-gateway"
	}
}


//route to internet
resource "aws_route" "my_vpc_internet_access" {
	route_table_id = aws_vpc.my_vpc.main_route_table_id # aws_default_route_table 과 같은 테이블, aws_default_route_table.my_vpc.id와도 같은 테이블
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.my_vpc_igw.id
}


// eip for NAT Gateway
resource "aws_eip" "my_vpc_nat_eip" {
	vpc = true
	depends_on = [ aws_internet_gateway.my_vpc_igw ] # 인터넷 게이트웨이 생성 이후 구성하기 위한 의존성
}

// NAT Gateway
// private subnet에서 외부 인터넷으로 요청을 내보낼 수 있도록 하기 위한 NAT 게이트웨이
resource "aws_nat_gateway" "my_vpc_nat" {
	allocation_id = aws_eip.my_vpc_nat_eip.id
	subnet_id = aws_subnet.my_vpc_public_subnet01.id
	depends_on = [ aws_internet_gateway.my_vpc_igw ] # 인터넷 게이트웨이 생성 이후 구성하기 위한 의존성
}

//private route table
resource "aws_route_table" "my_vpc_private_route_table" {
	vpc_id = aws_vpc.my_vpc.id

	tags = {
		Name = "private"
	}
}

// 프라이빗 서브넷에서 외부 인터넷으로 나가는 요청은 모두 NAT Gateway로 향함
resource "aws_route" "private_route" {
	route_table_id = aws_route_table.my_vpc_private_route_table.id
	destination_cidr_block = "0.0.0.0/0"
	nat_gateway_id = aws_nat_gateway.my_vpc_nat.id
}

// 생성한 라우트 테이블을 각각 퍼블릭/프라이빗 서브넷에 연결
resource "aws_route_table_association" "my_vpc_public_subnet01_association" {
  subnet_id = aws_subnet.my_vpc_public_subnet01.id
  route_table_id = aws_vpc.my_vpc.main_route_table_id
}

resource "aws_route_table_association" "my_vpc_public_subnet02_association" {
  subnet_id = aws_subnet.my_vpc_public_subnet02.id
  route_table_id = aws_vpc.my_vpc.main_route_table_id
}

resource "aws_route_table_association" "my_vpc_private_subnet01_association" {
  subnet_id = aws_subnet.my_vpc_private_subnet01.id
  route_table_id = aws_route_table.my_vpc_private_route_table.id
}

resource "aws_route_table_association" "my_vpc_private_subnet02_association" {
  subnet_id = aws_subnet.my_vpc_private_subnet02.id
  route_table_id = aws_route_table.my_vpc_private_route_table.id
}

//default security group - AWS가 생성한 SG를 테라폼이 관리 가능하게 지정한 것
resource "aws_default_security_group" "my_vpc_default" {
	vpc_id = aws_vpc.my_vpc.id

	ingress {
		protocol = -1
		self = true
		from_port = 0
		to_port = 0
	}
	egress {
		from_port = 0
		to_port = 0
		protocol = -1
		cidr_blocks = ["0.0.0.0/0"]
	}
	tags = {
		Name = "default"
	}
}

// AWS 기본 제공 ACL을 가지고 리소스 생성은 했으나 설정 및 다루기가 애매해 두기만 함
resource "aws_default_network_acl" "my_vpc_default" {
	default_network_acl_id = aws_vpc.my_vpc.default_network_acl_id
	
	ingress {
		protocol = -1
		rule_no = 100
		action = "allow"
		cidr_block = "0.0.0.0/0"
		from_port = 0
		to_port = 0
	}

	egress {
		protocol = -1
		rule_no = 100
		action = "allow"
		cidr_block = "0.0.0.0/0"
		from_port = 0
		to_port = 0
	}
	
	tags = {
		Name = "default"
	}
}

// network acl for public subnets
resource "aws_network_acl" "my_vpc_public" {
	vpc_id = aws_vpc.my_vpc.id
	subnet_ids = [ aws_subnet.my_vpc_public_subnet01.id, aws_subnet.my_vpc_public_subnet02.id ]

	tags = {
		Name = "public"
	}
}

resource "aws_network_acl_rule" "my_vpc_public_ingress80" {
	network_acl_id = aws_network_acl.my_vpc_public.id
	rule_number = 199
	rule_action = "allow"
	egress = false
	protocol = "tcp"
	cidr_block = "0.0.0.0/0"
	from_port = 80
	to_port = 80
}

resource "aws_network_acl_rule" "my_vpc_public_egress80" {
  network_acl_id = aws_network_acl.my_vpc_public.id
  rule_number = 100
  rule_action = "allow"
  egress = true
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}

resource "aws_network_acl_rule" "my_vpc_public_ingress443" {
  network_acl_id = aws_network_acl.my_vpc_public.id
  rule_number = 110
  rule_action = "allow"
  egress = false
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}

resource "aws_network_acl_rule" "my_vpc_public_egress443" {
  network_acl_id = aws_network_acl.my_vpc_public.id
  rule_number = 110
  rule_action = "allow"
  egress = true
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}

resource "aws_network_acl_rule" "my_vpc_public_ingress22" {
  network_acl_id = aws_network_acl.my_vpc_public.id
  rule_number = 120
  rule_action = "allow"
  egress = false
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 22
  to_port = 22
}

resource "aws_network_acl_rule" "my_vpc_public_egress22" {
  network_acl_id = aws_network_acl.my_vpc_public.id
  rule_number = 120
  rule_action = "allow"
  egress = true
  protocol = "tcp"
  cidr_block = aws_vpc.my_vpc.cidr_block
  from_port = 22
  to_port = 22
}

resource "aws_network_acl_rule" "my_vpc_public_ingress_ephemeral" {
  network_acl_id = aws_network_acl.my_vpc_public.id
  rule_number = 140
  rule_action = "allow"
  egress = false
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

// ephemeral : 임시 포트 (non-registered)
resource "aws_network_acl_rule" "my_vpc_public_egress_ephemeral" {
  network_acl_id = aws_network_acl.my_vpc_public.id
  rule_number = 140
  rule_action = "allow"
  egress = true
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

// network acl for private subnets
resource "aws_network_acl" "my_vpc_private" {
	vpc_id = aws_vpc.my_vpc.id
	subnet_ids = [ aws_subnet.my_vpc_private_subnet01.id, aws_subnet.my_vpc_private_subnet01.id ]

	tags = {
		Name = "private"
	}
}

// VPC 내에서는 모든 포트를 개방
// NAT로 들어오는 요청과 80, 44으로 나가는 요청을 규칙으로 추가해서 열어줌
resource "aws_network_acl_rule" "my_vpc_private_ingress_vpc" {
  network_acl_id = aws_network_acl.my_vpc_private.id
  rule_number = 100
  rule_action = "allow"
  egress = false
  protocol = -1
  cidr_block = aws_vpc.my_vpc.cidr_block
  from_port = 0
  to_port = 0
}

resource "aws_network_acl_rule" "my_vpc_private_egress_vpc" {
  network_acl_id = aws_network_acl.my_vpc_private.id
  rule_number = 100
  rule_action = "allow"
  egress = true
  protocol = -1
  cidr_block = aws_vpc.my_vpc.cidr_block
  from_port = 0
  to_port = 0
}

resource "aws_network_acl_rule" "my_vpc_private_ingress_nat" {
  network_acl_id = aws_network_acl.my_vpc_private.id
  rule_number = 110
  rule_action = "allow"
  egress = false
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

resource "aws_network_acl_rule" "my_vpc_private_egress80" {
  network_acl_id = aws_network_acl.my_vpc_private.id
  rule_number = 120
  rule_action = "allow"
  egress = true
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}

resource "aws_network_acl_rule" "my_vpc_private_egress443" {
  network_acl_id = aws_network_acl.my_vpc_private.id
  rule_number = 130
  rule_action = "allow"
  egress = true
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}


