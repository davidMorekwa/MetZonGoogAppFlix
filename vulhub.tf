# launch the vulhub docker containers on "victim" machine
resource "terraform_data" "vulhub_application" {
    input = {
        # these values will be store in the stat file
        compose_folder = var.compose_folder
        container_image = var.container_image
        user = var.remote_user
        pass = var.remote_user_password
    }
    triggers_replace = [
        # triggers the destroy-create cycle
        var.compose_folder,
    ]
    connection {
        type = "ssh"
        user = self.input.user
        password = self.input.pass
        host = "victim.taila3159b.ts.net"
    }
    provisioner "remote-exec" {
        inline = [ 
            # build image, run scan script, run container, get port
            "docker compose -f /home/${self.input.user}/vulhub/${self.input.compose_folder}/docker-compose.yml build",
            # "/home/${self.input.user}/vulhub/scanner.py --image ${self.input.container_image}", # <-- scans the docker image for vulnerabilities using trivy then exports the report in txt format to the ./vuln_reports folder via sftp
            "docker compose -f /home/${self.input.user}/vulhub/${self.input.compose_folder}/docker-compose.yml up -d",
            "docker ps --format {{.Ports}}"
        ] 
    }

    provisioner "remote-exec" {
        when = destroy
        inline = [ 
            "docker compose -f /home/${self.input.user}/vulhub/${self.input.compose_folder}/docker-compose.yml down"
        ]
    }
}

variable "remote_user" {}
variable "remote_user_password" {}
variable "compose_folder" {} # e.g. livewire/CVE-2025-54068
variable "container_image" {}