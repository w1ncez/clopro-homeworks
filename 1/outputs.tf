output "public_vm_external_ip" {
  value       = yandex_compute_instance.public-vm.network_interface.0.nat_ip_address
  description = "Публичный IP-адрес виртуальной машины в публичной подсети"
}

output "nat_instance_internal_ip" {
  value       = yandex_compute_instance.nat-instance.network_interface.0.ip_address
  description = "Внутренний IP NAT-инстанса"
}
