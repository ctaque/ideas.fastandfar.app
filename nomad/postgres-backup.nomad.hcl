job "postgres-backup-store-rails" {
  datacenters = ["dc1"]
  type        = "batch"

  # Ajuste l'horaire / le fuseau selon tes besoins
  periodic {
    cron             = "15 3 * * *" # tous les jours à 03h00
    time_zone        = "Europe/Paris"
    prohibit_overlap = true
  }

  group "backup" {
    count = 1

    # C'est un batch job ponctuel : pas de relance en boucle en cas d'échec,
    # la prochaine exécution périodique s'en chargera.
    restart {
      attempts = 1
      delay    = "30s"
      mode     = "fail"
    }

    reschedule {
      attempts = 0
      unlimited = false
    }

    task "pg-dump-s3" {
      driver = "raw_exec"
      config {
        # command doit être un exécutable, pas une chaîne shell complète :
        # on passe par bash -c pour que les $VAR soient bien expansés.
        command = "/bin/bash"
        args = [
          "-c",
          "/root/scripts/backup-db.sh \"$DATABASE_URL\" \"$S3_BUCKET\" \"$RETENTION_DAYS\""
        ]
      }

      # Secrets et config injectés depuis les variables Nomad
      # (créées au préalable avec `nomad var put`, cf. note ci-dessous)
      template {
        data = <<-EOT
        {{- with nomadVar "nomad/jobs/postgres-backup-store-rails" }}
        DATABASE_URL={{ .DATABASE_URL }}
        S3_BUCKET={{ .S3_BUCKET }}
        RETENTION_DAYS={{ .RETENTION_DAYS }}
        AWS_ACCESS_KEY_ID={{ .AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY={{ .AWS_SECRET_ACCESS_KEY }}
        AWS_DEFAULT_REGION={{ .AWS_DEFAULT_REGION }}
        {{- end }}
        EOT

        destination = "secrets/backup.env"
        env         = true
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}
