# devices
data "tailscale_device" "linux_victim" {
    name = "victim.taila3159b.ts.net"
}
data "tailscale_device" "linux_attacker" {
    name = "kali.taila3159b.ts.net"
}
data "tailscale_device" "windows_victim" {
    name = "windows.taila3159b.ts.net"
}
data "tailscale_device" "macos" {
    name = "macos.taila3159b.ts.net"
}

resource "tailscale_acl" "homelab_acl" {
    acl = jsonencode({
        "tagOwners" = {
            "tag:attacker" = [var.tailscale_tag_owner]
            "tag:victim" = [var.tailscale_tag_owner] # target 
            "tag:admin" = [var.tailscale_tag_owner]
            "tag:soc" = ["davidMorekwa@github"] # wazuh 
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
                "users"= ["root", "david", "kali"]
            },
        ] 
    })
    reset_acl_on_destroy = true
}

#apply tags to devices
# resource "tailscale_device_tags" "linux_victim_tag" {
#     device_id = data.tailscale_device.linux_victim.node_id
#     tags = ["tag:victim"]
# }
# resource "tailscale_device_tags" "windows_victim_tag" {
#     device_id = data.tailscale_device.windows_victim.node_id
#     tags = ["tag:victim"]
# }
# resource "tailscale_device_tags" "macos_admin_tag" {
#     device_id = data.tailscale_device.macos.node_id
#     tags = ["tag:admin"]
# }
# resource "tailscale_device_tags" "kali_attacker_tag" {
#     device_id = data.tailscale_device.linux_attacker.node_id
#     tags = ["tag:attacker"]
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