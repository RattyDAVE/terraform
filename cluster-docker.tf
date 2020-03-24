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
  default = "1"
}


# Start a container
resource "docker_container" "httptest" {
 count = ${var.instance_count}
 name  = "httptest.${count.index}"
 image = "rattydave/httptest"
 ports {
    protocol = "tcp"
    internal = "8000"
  }
 volumes {
   host_path = "/root/dockertest"
   container_path = "/root/test"
 }
 env = ["VIRTUAL_HOST=${var.hostname},httptest${count.index}.${var.hostname}", "VIRTUAL_PORT=${docker_container.httptest.ports.internal}", "LETSENCRYPT_HOST=${var.hostname}"]
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
 volumes {
  host_path = "/var/run/docker.sock"
  container_path = "/var/run/docker.sock"
  read_only = true
 }
 volumes {
  from_container = "nginx-proxy"
 }
}
