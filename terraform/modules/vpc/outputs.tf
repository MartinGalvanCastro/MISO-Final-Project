# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

# NAT Gateway Outputs
output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# Route Table Outputs
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

# VPC Endpoint Outputs
output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = var.create_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}

# Availability Zones
output "availability_zones" {
  description = "List of availability zones used"
  value       = data.aws_availability_zones.available.names
}

# Complete VPC Information
output "vpc_info" {
  description = "Complete VPC information"
  value = {
    vpc_id               = aws_vpc.main.id
    vpc_cidr_block       = aws_vpc.main.cidr_block
    public_subnet_ids    = aws_subnet.public[*].id
    private_subnet_ids   = aws_subnet.private[*].id
    internet_gateway_id  = aws_internet_gateway.main.id
    nat_gateway_ids      = aws_nat_gateway.main[*].id
    availability_zones   = data.aws_availability_zones.available.names
  }
}