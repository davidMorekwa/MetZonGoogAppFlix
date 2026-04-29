# launch the vulhub docker containers on "victim" machine
resource "terraform_data" "vulhub_application" {
    input = {
        # these values will be store in the stat file
        remote_compose_folder = var.compose_folder
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
            "docker compose -f /home/david/vulhub/${var.compose_folder}/docker-compose.yml up -d",
            "docker ps --format {{.Ports}}"
        ] 
    }

    provisioner "remote-exec" {
        when = destroy
        inline = [ 
            "docker compose -f /home/${self.input.user}/vulhub/${self.input.remote_compose_folder}/docker-compose.yml down"
        ]
    }
}

variable "remote_user" {}
variable "remote_user_password" {}
variable "compose_folder" {} # e.g. livewire/CVE-2025-54068