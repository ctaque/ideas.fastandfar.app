variable "image" {
  type        = string
  description = "Docker image reference for the store app (e.g. localhost:5555/store:latest)"
  default     = "localhost:5555/store:latest"
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
      mode = "bridge"

      port "http" {
        to = 80
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
      }

      volume_mount {
        volume      = "store_storage"
        destination = "/rails/storage"
      }

      env {
        SOLID_QUEUE_IN_PUMA = "true"
      }

      template {
        data        = <<-EOT
          RAILS_MASTER_KEY={{ with nomadVar "nomad/jobs/store" }}{{ .RAILS_MASTER_KEY }}{{ end }}
          ANTHROPIC_API_KEY={{ with nomadVar "nomad/jobs/store" }}{{ .ANTHROPIC_API_KEY }}{{ end }}
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
