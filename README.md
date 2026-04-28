# MetZonGoogAppFlix: Hybrid SOC & Cyber-Range

This repository contains **Terraform** configuration to setup my homelab environment. The homelab is designed to simulate modern enterprise detection and response. By bridging a cloud-based Security Operations Center (SOC) with a local-area network (LAN) via a Zero-Trust mesh (Tailscale), this project provides a realistic environment for both offensive and defensive security operations.


## Architecture Overview
This is a **Hybrid-Cloud** deployment. While the SIEM is hosted on Linode, the primary "Battlefield" resides on a local area network (LAN).

- **Cloud SOC:** A Linode instance running Wazuh (SIEM/XDR) in Docker.
- **LAN Battlefield:** 
    - **Victims:** Local Windows machine and Ubuntu Linux VM monitored by the cloud SIEM.
    - **Attacker:** A local Kali Linux VM instance simulating threats/shadow IT
    - **Admin:** A local admin machine with access to the cloud SIEM
- **The Bridge:** Tailscale creates an encrypted overlay network, allowing local LAN devices to ship logs to the Cloud SOC without opening any firewall ports on the home router.

## Features
- **Zero Public Surface:** Linode firewalls are set to `DROP` all inbound traffic. Access is granted only via encrypted Tailscale tunnels.
- **Infrastructure as Code:** - Automated Wazuh installation via Linode StackScripts.
    - Identity-based access control via Tailscale ACLs (HCL-based).
- **Network IDS/IPS:** The victim machines i.e. windows and linux, should have suricata installed for network security monitoring
- **Stealth Monitoring:** Managed through Tailscale Tags, allowing for "Rogue Device" simulation where the attacker is unmanaged but the victims are monitored.

## Deployment

### Prerequisites
### Prerequisites
1. **Tailscale:** All local machines must have the Tailscale client installed and be logged in.
2. **Suricata:** The victim machines should have suricata installed and configured to monitor on the **tailscale** interface e.g. `tailscale0`
2. **Linode Token:** For the cloud-based Wazuh manager.
3. **Terraform installed** on your local "admin" machine.

### Instructions
1. **Clone the repo:**
   ```bash
   git clone https://github.com/your-username/stealth-siem-lab.git
   cd stealth-siem-lab
   ```

2. **Initialize Variables:**
   Create a `terraform.tfvars` file:
   ```hcl
   linode_token      = "your-linode-api-token"
   linode_root_pass = "linode-root-user-password"
   linode_region = "desired-linode-region"
   tailscale_api_key = "your-tailscale-key"
   tailscale_tailnet = "your-tailnet-ID"
   tailscale_tag_owner = "user@example.com"
   ```

3. **Initialize & Apply:**
   ```bash
   terraform init
   terraform apply
   ```

4. **Verify Deployment:**
   1. Check your Tailscale Admin console for the `wazuh` node.
   2. From the admin machine web browser, visit [wazuh](https://wazuh) and login with the default credentials `admin:SecretPassword`. **MAKE SURE YOU CHANGE THESE DEFAULT CREDENTIALS**

## Networking & Security Policy
The project uses `reset_acl_on_destroy = true` to ensure clean lifecycle management. The ACL policy is strictly enforced:
- `tag:admin` has full access to all nodes.
- `tag:victim` can only communicate with the SIEM on ports `1514/1515`.
- `tag:attacker` is allowed to interact with `tag:victim` but is blocked from the `tag:soc`.

## Cleanup
To tear down the entire lab:
```bash
terraform destroy
```

## Future Improvements:
- While the "admin" machine is configured to access all devices on the tailscale network, it violates the Principle of Least Privileges. Therefore, future improvement plans involves hardening the network by splitting the `tag:admin` into specialized roles e.g. manager, audit etc.
- Secondly, the repository will constain custom detection rules for both wazuh and suricata to detect security incidents. Its not enough to just setup the homelab!!
- Finally, integration of OpenVAS for vulnerability management of the MetZonGoogAppFlix "corporate" endpoints