
resource "yandex_compute_instance_group" "lamp-group" {
  name               = "lamp-instance-group"
  folder_id          = var.folder_id
  service_account_id = yandex_iam_service_account.ig-sa.id

  description = "Three LAMP web servers"

  instance_template {
    platform_id = "standard-v2"

    resources {
      cores  = 2
      memory = 2
    }

    boot_disk {
      mode = "READ_WRITE"

      initialize_params {
        image_id = "fd827b91d99psvq5fjit"
        size     = 20
      }
    }

    network_interface {
      network_id         = yandex_vpc_network.main-net.id
      subnet_ids         = [yandex_vpc_subnet.public.id]
      nat                = true
      security_group_ids = [yandex_vpc_security_group.lamp-sg.id]
    }

    scheduling_policy {
      preemptible = true
    }

    metadata = {
      ssh-keys = "cloud-user:${file(var.ssh_public_key_path)}"

      user-data = <<-EOF
        #cloud-config
        runcmd:
          - |
            cat > /var/www/html/index.html <<'HTML'
            <!DOCTYPE html>
            <html lang="ru">
            <head>
              <meta charset="UTF-8">
              <title>Yandex Cloud LAMP</title>
              <style>
                body {
                  font-family: Arial, sans-serif;
                  text-align: center;
                  margin-top: 50px;
                  background: #f4f4f4;
                }
                img {
                  max-width: 600px;
                  width: 90%;
                  border-radius: 10px;
                }
              </style>
            </head>
            <body>
              <h1>Yandex Cloud - LAMP Instance Group</h1>
              <h2>Веб-сервер работает!</h2>
              <img src="${var.image_url}" alt="Image from Object Storage">
              <p>Изображение загружается из Yandex Object Storage.</p>
            </body>
            </html>
            HTML
            echo "<p>Hostname: $(hostname)</p>" >> /var/www/html/index.html
      EOF
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    max_unavailable = 1
    max_creating    = 3
    max_expansion   = 1
    max_deleting    = 1
  }

  load_balancer {
    target_group_name = "lamp-target-group"
  }

  health_check {
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3

    http_options {
      port = 80
      path = "/"
    }
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.ig-compute-admin,
    yandex_resourcemanager_folder_iam_member.ig-vpc-user
  ]
}
