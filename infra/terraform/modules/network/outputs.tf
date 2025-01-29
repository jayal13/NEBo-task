output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "vpc_route_table_id" {
  value = aws_vpc.main.default_route_table_id
}

output "public_route_table" {
  value = aws_route_table.public.id
}