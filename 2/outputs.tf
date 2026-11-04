output "nlb_external_ip" {
  description = "Публичный IP Network Load Balancer"

  value = one([
    for listener in yandex_lb_network_load_balancer.lamp-nlb.listener :
    one(listener.external_address_spec).address
  ])
}
