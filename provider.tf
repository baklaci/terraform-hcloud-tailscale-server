terraform {
  # the removed block with lifecycle in main.tf; tested with OpenTofu 1.12
  required_version = ">= 1.9"

  required_providers {
    tailscale = {
      source = "tailscale/tailscale"
      version = "~> 0.17" 
    }
   hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}
