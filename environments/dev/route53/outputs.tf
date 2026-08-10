output "zone_id" {
  description = "Hosted zone ID"
  value       = module.route53.zone_id
}

output "name_servers" {
  description = "Name servers for the hosted zone"
  value       = module.route53.name_servers
}
