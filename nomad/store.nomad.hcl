variable "image" {
  type        = string
  description = "Docker image reference for the store app (e.g. docker-hub.fastandfar.app/ctaque/store:latest)"
  default     = "docker-hub.fastandfar.app/ctaque/store:latest"
}

variable "docker_username" {
  type        = string
  description = "Username for pulling the image from the private Docker registry"
  default     = ""
}

variable "docker_password" {
  type        = string
  description = "Password for pulling the image from the private Docker registry"
  default     = ""
}

job "store" {
  datacenters = ["dc1"]
  type        = "service"

  update {
    max_parallel      = 1
    canary            = 1
    auto_revert       = true
    auto_promote      = true
    health_check      = "checks"
    min_healthy_time  = "10s"
    healthy_deadline  = "3m"
  }

  group "web" {
    count = 1

    network {
      mode = "host"

      port "http" {
        static = 8085
      }
    }

    volume "store_storage" {
      type      = "host"
      source    = "store_storage"
      read_only = false
    }

    service {
      name     = "store"
      port     = "http"
      provider = "nomad"

      check {
        type     = "http"
        path     = "/up"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "store" {
      driver = "docker"

      config {
        image = var.image
        ports = ["http"]

        auth {
          username = var.docker_username
          password = var.docker_password
        }
      }

      volume_mount {
        volume      = "store_storage"
        destination = "/rails/storage"
      }

      env {
        HTTP_PORT   = "${NOMAD_PORT_http}"
        TARGET_PORT = "13000"
      }

      template {
        data        = <<-EOT
          RAILS_MASTER_KEY={{ with nomadVar "nomad/jobs/store" }}{{ .RAILS_MASTER_KEY }}{{ end }}
          SECRET_KEY_BASE={{ with nomadVar "nomad/jobs/store" }}{{ .SECRET_KEY_BASE }}{{ end }}
          ANTHROPIC_API_KEY={{ with nomadVar "nomad/jobs/store" }}{{ .ANTHROPIC_API_KEY }}{{ end }}
          DOCKER_USERNAME={{ with nomadVar "nomad/jobs/store" }}{{ .DOCKER_USERNAME }}{{ end }}
          DOCKER_PASSWORD={{ with nomadVar "nomad/jobs/store" }}{{ .DOCKER_PASSWORD }}{{ end }}
          STORE_JWT_PUBLIC_KEY={{ with nomadVar "nomad/jobs/store" }}{{ .STORE_JWT_PUBLIC_KEY.Value | base64Decode | toJSON }}{{ end }}
          DB_HOST={{ with nomadVar "nomad/jobs/store" }}{{ .DB_HOST }}{{ end }}
          DB_PORT={{ with nomadVar "nomad/jobs/store" }}{{ .DB_PORT }}{{ end }}
          DB_USERNAME={{ with nomadVar "nomad/jobs/store" }}{{ .DB_USERNAME }}{{ end }}
          DB_PASSWORD={{ with nomadVar "nomad/jobs/store" }}{{ .DB_PASSWORD }}{{ end }}
          STORE_LOGIN_BRIDGE_URL={{ with nomadVar "nomad/jobs/store" }}{{ .STORE_LOGIN_BRIDGE_URL }}{{ end }}
          AWS_ACCESS_KEY_ID={{ with nomadVar "nomad/jobs/store" }}{{ .AWS_ACCESS_KEY_ID }}{{ end }}
          AWS_SECRET_ACCESS_KEY={{ with nomadVar "nomad/jobs/store" }}{{ .AWS_SECRET_ACCESS_KEY }}{{ end }}
          AWS_REGION={{ with nomadVar "nomad/jobs/store" }}{{ .AWS_REGION }}{{ end }}
          AWS_BUCKET={{ with nomadVar "nomad/jobs/store" }}{{ .AWS_BUCKET }}{{ end }}
        EOT
        destination = "secrets/env.env"
        env         = true
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}

