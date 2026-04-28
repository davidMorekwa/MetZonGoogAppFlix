# devices
# after installing the tailscale client, add the devices here using:
# data "tailscale_device" "linux_victim" {
#     name = "device-fqdn"
# }
# reference: https://registry.terraform.io/providers/tailscale/tailscale/latest/docs/data-sources/device


resource "tailscale_acl" "homelab_acl" {
    acl = jsonencode({
        "tagOwners" = {
            "tag:attacker" = [var.tailscale_tag_owner]
            "tag:victim" = [var.tailscale_tag_owner] # target machines
            "tag:admin" = [var.tailscale_tag_owner]
            "tag:soc" = [var.tailscale_tag_owner] # wazuh 
        }
        "grants" = [
            {
                # admin access all devices
                src = ["tag:admin"]
                dst = ["*"]
                ip = ["*"]
            },
            {
                # victim machines communicate with wazuh
                src = ["tag:victim"]
                dst = ["tag:soc"]
                ip = ["tcp:1514", "tcp:1515"]
            },
            {
                # attacker machine able to reach victim
                src = ["tag:attacker"]
                dst = ["tag:victim"]
                ip = ["*"]
            },
        ]
        "ssh" = [
            {
                #admin ssh access
                "action"= "accept"
                "src"= ["tag:admin"] 
                "dst"= ["tag:soc", "tag:victim"]
                "users"= ["root", "david", "kali"] # <-- change to users with remote login allowed on the victim and attacker machines, and cloud VM
            },
        ] 
    })
    reset_acl_on_destroy = true
}

# uncomment the block below to apply tags to devices. Reference: https://registry.terraform.io/providers/tailscale/tailscale/latest/docs/resources/device_tags
# resource "tailscale_device_tags" "linux_victim_tag" {
#     device_id = data.tailscale_device.linux_victim.node_id
#     tags = ["tag:victim"]
# }

resource "tailscale_tailnet_key" "wazuh_key" {
  reusable      = false
  preauthorized = true
  ephemeral = true
  tags          = ["tag:soc"]
  description = "Wazuh authentication key"
  expiry = "72000" # 20hrs
}

variable "tailscale_tag_owner" {}
variable "tailscale_api_key" {}
variable "tailscale_tailnet_id" {}