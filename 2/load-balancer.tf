resource "yandex_lb_network_load_balancer" "lamp-nlb" {
  name = "lamp-network-load-balancer"

  listener {
    name        = "http-listener"
    port        = 80
    target_port = 80
    protocol    = "tcp"

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.lamp-group.load_balancer[0].target_group_id

    healthcheck {
      name                = "lamp-http-check"
      interval            = 10
      timeout             = 5
      healthy_threshold   = 2
      unhealthy_threshold = 3

      http_options {
        port = 80
        path = "/"
      }
    }
  }
}
