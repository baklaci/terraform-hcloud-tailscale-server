# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "server_name" {
  description = "Name of the server"
  type        = string
}

variable "image" {
    description = "The image ID that will be used to create the instance"
    type = string
}

variable "server_type" {
    description = "The Hetzner server type that will be used to create the instance"
    type = string
}

variable "location" {
    description = "The Hetzner location code that will be used to create the instance"
    type = string
}

variable "ssh_keys" {
    description = "The public key that will be used to check ssh access. Fill only the first in the list"
    type = list(string)
}

variable "runcmd" {
    description = "The runcommand part of the cloud_init script"
    type = string
    default = ""
}

variable "username" {
    description = "The username for the created user on the server"
    type = string
    default = "sprantic"
}

variable "tailscale_api_key" {
    description = "Deprecated and unused: the cleanup on destroy reads TAILSCALE_API_KEY (or TF_VAR_tailscale_api_key) from the environment, so the key is not stored in the state. Kept so existing callers do not break."
    type = string
    sensitive = true
    default = null
}

variable "tailscale_tailnet" {
    description = "Tailscale tailnet name (e.g., 'example.com' or 'user@domain.com')"
    type = string
}

variable "docker_compose_yaml" {
    description = "Docker Compose YAML configuration to be deployed on the server"
    type = string
    default = ""
}

variable "docker_compose_project_name" {
    description = "Name for the Docker Compose project (defaults to server name)"
    type = string
    default = ""
}

variable "ephemeral" {
    description = "Join Tailscale as an ephemeral node. Ephemeral nodes are removed by Tailscale after being offline for a while, and the one-time auth key cannot bring them back, so set false for long-lived servers. Changing it on an existing server replaces the server."
    type = bool
    default = true
}

variable "public_tcp_ports" {
    description = "Inbound TCP ports open to the internet, each with its allowed source ranges. The default keeps the earlier behaviour (port 80 from anywhere); use [] for a server reached only over Tailscale."
    type = list(object({
        port       = string
        source_ips = list(string)
    }))
    default = [
        {
            port       = "80"
            source_ips = ["0.0.0.0/0", "::/0"]
        }
    ]
}
