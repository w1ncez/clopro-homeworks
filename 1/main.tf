public_vm_external_ip = "51.250.73.201"
root@master-1:/home/w1nce# nano main.tf
  GNU nano 7.2                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   main.tf
# VPC
resource "yandex_vpc_network" "main-net" {
  name = "main-network"
}

# Публичная подсеть
resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main-net.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Приватная подсеть
resource "yandex_vpc_subnet" "private" {
  name           = "private"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main-net.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.private-rt.id
}

# Создание NAT-инстанса
resource "yandex_compute_instance" "nat-instance" {
  name        = "nat-instance"
  hostname    = "nat-instance"
  platform_id = "standard-v2"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1"
      size     = 6
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = true
    ip_address         = "192.168.10.254"
    security_group_ids = [yandex_vpc_security_group.nat-sg.id]
  }

  metadata = {
    user-data = <<EOF
# cloud-config
users:
  - name: cloud-user
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${file("/home/w1nce/id_ed25519.pub")}
runcmd:
  - sysctl -w net.ipv4.ip_forward=1
  - iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  - iptables-save > /etc/iptables/rules.v4
EOF
  }
}

# Группа безопасности для NAT-инстанса
resource "yandex_vpc_security_group" "nat-sg" {
  name       = "nat-sg"
  network_id = yandex_vpc_network.main-net.id

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  # Разрешаем трафик из приватной подсети
  ingress {
    protocol       = "ANY"
    description    = "Allow from private subnet"
    v4_cidr_blocks = ["192.168.20.0/24"]
  }

  # Разрешаем трафик из публичной подсети
  ingress {
    protocol       = "ANY"
    description    = "Allow from public subnet"
    v4_cidr_blocks = ["192.168.10.0/24"]
  }
}

# Таблица маршрутизации для приватной подсети
resource "yandex_vpc_route_table" "private-rt" {
  name       = "private-rt"
  network_id = yandex_vpc_network.main-net.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254"
  }
}

#  Публичная виртуальная машина
resource "yandex_compute_instance" "public-vm" {
  name        = "public-vm"
  hostname    = "public-vm"
  platform_id = "standard-v2"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd8tqd3ee9ii1avc9o5e"
      size     = 20
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = true
    ip_address         = "192.168.10.10"
    security_group_ids = [yandex_vpc_security_group.vm-sg.id]
  }

  metadata = {
    user-data = <<EOF
# cloud-config
users:
  - name: cloud-user
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${file("/home/w1nce/id_ed25519.pub")}
EOF
  }
}

# Приватная виртуальная машина
resource "yandex_compute_instance" "private-vm" {
  name        = "private-vm"
  hostname    = "private-vm"
  platform_id = "standard-v2"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd8tqd3ee9ii1avc9o5e"
      size     = 20
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private.id
    nat                = false
    ip_address         = "192.168.20.10"
    security_group_ids = [yandex_vpc_security_group.vm-sg.id]
  }

  metadata = {
    user-data = <<EOF
# cloud-config
users:
  - name: cloud-user
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${file("/home/w1nce/id_ed25519.pub")}
EOF
  }
}

# Общая группа безопасности для ВМ (разрешить SSH между ними)
resource "yandex_vpc_security_group" "vm-sg" {
  name       = "vm-sg"
  network_id = yandex_vpc_network.main-net.id

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH from public subnet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH from private subnet"
    v4_cidr_blocks = ["192.168.20.0/24","192.168.10.0/24"]
    port           = 22
  }
}



