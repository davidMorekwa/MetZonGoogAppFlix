
data "linode_sshkey" "my_key" {
  label = "openvas" # <-- may use a ssh already existing on or create a new one. Reference: https://registry.terraform.io/providers/linode/linode/latest/docs/resources/sshkey
}

resource "linode_stackscript" "my_script" {
  label = "my_script"
  description = "Script to bootstrap the linode instance"
  script = <<EOF
#!/bin/bash
# <UDF name="auth_key" label="auth_key to join tailscale network" default="">

set -e

echo 'Updating system'
export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
apt -q update
apt -y -q -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

echo 'Setting hostname'
hostnamectl hostname wazuh

echo 'install tailscale'
curl -fsSL https://tailscale.com/install.sh | sh

echo 'log into tailscale'
tailscale login --hostname=wazuh --auth-key=$AUTH_KEY

echo 'Installing docker'
# Add Docker's official GPG key:
apt -q update
apt install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
tee /etc/apt/sources.list.d/docker.sources <<EOF_DOCKER
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF_DOCKER

apt -q update

apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo 'Installing wazuh docker container'

git clone https://github.com/wazuh/wazuh-docker.git -b v4.14.5
docker compose -f wazuh-docker/single-node/generate-indexer-certs.yml run --rm generator
docker compose -f wazuh-docker/single-node/docker-compose.yml up -d
echo 'setup custom auditd decoder'
docker compose exec -f wazuh-docker/single-node/docker-compose.yml -it wazuh.manager curl https://raw.githubusercontent.com/davidMorekwa/wazuh-docker/refs/heads/main/single-node/auditd_custom_decoder.xml -o /wazuh-config-mount/etc/0040-auditd_decoders.xml
docker compose exec -f wazuh-docker/single-node/docker-compose.yml -it wazuh.manager cp /wazuh-config-mount/etc/0040-auditd_decoders.xml /var/ossec/ruleset/decoders/
echo 'setup custom detection rules'
docker compose exec -f wazuh-docker/single-node/docker-compose.yml -it wazuh.manager curl https://raw.githubusercontent.com/davidMorekwa/wazuh-docker/refs/heads/main/single-node/local_rules.xml -o /wazuh-config-mount/etc/local_rules.xml
docker compose exec -f wazuh-docker/single-node/docker-compose.yml -it wazuh.manager cp /wazuh-config-mount/etc/local_rules.xml /var/ossec/etc/rules/
  EOF
  images = ["linode/ubuntu24.04"]
  rev_note = "v1.1" 
}

resource "linode_firewall" "soc_firewall" {
  label = "soc_stealth_terfirewall"
  inbound_policy = "DROP"
  outbound_policy = "ACCEPT"
}

resource "linode_instance" "wazuh" {
  label = "Wazuh"
  region = var.linode_region
  image = "linode/ubuntu24.04"
  root_pass = var.linode_root_pass
  type = "g6-standard-4"
  authorized_keys = [data.linode_sshkey.my_key.ssh_key]
  firewall_id = linode_firewall.soc_firewall.id
  stackscript_id = linode_stackscript.my_script.id
  stackscript_data = {
    "auth_key" = tailscale_tailnet_key.wazuh_key.key
  }
}

output "vm_public_ip" {
  value = linode_instance.wazuh.ipv4
  description = "VM Instance IP"
}

variable "linode_token" {}
variable "linode_region" {}
variable "linode_root_pass" {}