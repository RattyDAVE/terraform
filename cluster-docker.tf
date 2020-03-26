variable "hostname" {
  description = "Hostname for Cluster"
  default = "xxxx.example.com"
}

variable "container_port" {
  description = "Inside Container Port"
  default = "8000"
}


variable "instance_count" {
  description = "Instance count for httptest"
  default = "10"
}


resource "docker_container" "nginx-proxy" {
 name  = "nginx-proxy"
 image = "jwilder/nginx-proxy"
 ports {
  protocol = "tcp"
  internal = "443"
  external = "443"  
 }
 ports {
  protocol = "tcp"
  internal = "80"
  external = "80"
 }
 volumes {
  container_path = "/etc/nginx/certs"
 }
 volumes {
  container_path = "/etc/nginx/vhost.d"
 }
 volumes {
  container_path = "/usr/share/nginx/html"
 }
 volumes {
  host_path = "/var/run/docker.sock"
  container_path = "/tmp/docker.sock"
  read_only = true
 }
}

resource "docker_container" "nginx-proxy-letsencrypt" {
 name  = "nginx-proxy-letsencrypt"
 image = "jrcs/letsencrypt-nginx-proxy-companion"
 depends_on = [docker_container.nginx-proxy]
 volumes {
  host_path = "/var/run/docker.sock"
  container_path = "/var/run/docker.sock"
  read_only = true
 }
 volumes {
  from_container = "nginx-proxy"
 }
}

resource "docker_container" "httptest" {
 count = var.instance_count
 name  = "instance.${count.index}"
 image = "rattydave/httptest"
 depends_on = [docker_container.nginx-proxy]
 #ports {
 #   protocol = "tcp"
 #   internal = "8000"
 # }
 env = ["VIRTUAL_HOST=${var.hostname},httptest${count.index}.${var.hostname}", "VIRTUAL_PORT=${var.container_port}", "LETSENCRYPT_HOST=${var.hostname}"]
}


