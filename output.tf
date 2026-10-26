output "ip_address" {
  value = hcloud_server.server.ipv4_address
}

output "server_id" {
  value = hcloud_server.server.id
}

output "location" {
  value = hcloud_server.server.location
}
