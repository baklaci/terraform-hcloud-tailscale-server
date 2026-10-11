resource "tailscale_tailnet_key" "server_key" {
  reusable      = false
  ephemeral     = var.ephemeral
  preauthorized = true
  expiry        = 3600
  description   = substr(format("Key for %s", var.server_name), 0, 50)
}

resource "hcloud_server" "server" {
  name         = var.server_name
  image        = var.image
  server_type  = var.server_type
  location     = var.location
  firewall_ids = [hcloud_firewall.server_firewall.id]
  # the cloud init file consists of the "management part" which is coming from the module and the "runcmd part" which is coming from the module user.
  ssh_keys  = [data.hcloud_ssh_key.me.id]
  user_data = data.cloudinit_config.idp.rendered
}

# Separate resource for Tailscale device cleanup.
# The API key is read from the environment at destroy time instead of being
# stored in triggers, so it never lands in the state file.
resource "null_resource" "tailscale_device_cleanup" {
  depends_on = [hcloud_server.server]

  triggers = {
    server_id   = hcloud_server.server.id
    server_name = var.server_name
    tailnet     = var.tailscale_tailnet
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      set -eu
      KEY="$${TAILSCALE_API_KEY:-$${TF_VAR_tailscale_api_key:-}}"
      if [ -z "$KEY" ]; then
        echo "TAILSCALE_API_KEY not set: remove device ${self.triggers.server_name} in the Tailscale admin console" >&2
        exit 0
      fi

      sleep 5

      DEVICE_ID=$(curl -fsS -H "Authorization: Bearer $KEY" \
        "https://api.tailscale.com/api/v2/tailnet/${self.triggers.tailnet}/devices" | \
        jq -r '.devices[] | select(.hostname == "${self.triggers.server_name}") | .id')

      if [ -n "$DEVICE_ID" ] && [ "$DEVICE_ID" != "null" ]; then
        echo "Removing Tailscale device: ${self.triggers.server_name} (ID: $DEVICE_ID)"
        curl -fsS -X DELETE -H "Authorization: Bearer $KEY" \
          "https://api.tailscale.com/api/v2/device/$DEVICE_ID"
        echo "Tailscale device removed successfully"
      else
        echo "Tailscale device ${self.triggers.server_name} not found or already removed"
      fi
    EOT
  }
}

# The previous cleanup resource kept the API key in its triggers, so in the
# state. Forget it without running its destroy step: destroying it would
# remove the live server from the tailnet.
removed {
  from = null_resource.tailscale_cleanup
  lifecycle {
    destroy = false
  }
}

# we don't need port 22 due to tailscale
resource "hcloud_firewall" "server_firewall" {
  name = format("%s-firewall", var.server_name)
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "udp"
    port      = "41641"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "out"
    protocol  = "udp"
    port      = "3478"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # we can skip that last rule later if everything runs stable
  rule {
    direction       = "out"
    protocol        = "tcp"
    destination_ips = ["0.0.0.0/0"]
    port            = "1-65535"
  }

  dynamic "rule" {
    for_each = var.public_tcp_ports
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = rule.value.port
      source_ips = rule.value.source_ips
    }
  }

}

