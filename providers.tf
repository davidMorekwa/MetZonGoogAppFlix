terraform {
  required_providers {
    linode = {
        source = "linode/linode"
        version = "3.11.0"
    }
    tailscale = {
            source = "tailscale/tailscale"
            version = "0.28.0"
    }
    # docker = {
    #     source  = "docker/docker"
    #     version = "0.6.0"
    # }
  }
}
provider "linode" {
    token = var.linode_token
}
provider "tailscale" {
    api_key = var.tailscale_api_key
    tailnet = var.tailscale_tailnet_id
}
# provider "docker" {

# }