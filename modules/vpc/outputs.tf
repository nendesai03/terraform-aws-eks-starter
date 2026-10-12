output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (use these for EKS nodes)."
  value       = aws_subnet.private[*].id
}

output "availability_zones" {
  description = "Availability Zones used."
  value       = local.azs
}

output "nat_public_ips" {
  description = "Public IPs of the NAT gateway(s), useful for allow-listing."
  value       = aws_eip.nat[*].public_ip
}