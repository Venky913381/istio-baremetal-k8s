output "hosted_zone_id" {
  description = "ID of the hosted zone"
  value       = try(aws_route53_zone.main.zone_id, null)
}

output "name_servers" {
  description = "Name servers for the hosted zone"
  value       = try(aws_route53_zone.main.name_servers, [])
}

output "health_check_id" {
  description = "ID of the health check"
  value       = try(aws_route53_health_check.main.id, null)
}
