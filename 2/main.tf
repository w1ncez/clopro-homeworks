
resource "yandex_vpc_network" "main-net" {
  name = "main-network"
}


resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main-net.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}


resource "yandex_vpc_security_group" "lamp-sg" {
  name       = "lamp-sg"
  network_id = yandex_vpc_network.main-net.id

  # HTTP
  ingress {
    protocol       = "TCP"
    description    = "Allow HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  # SSH
  ingress {
    protocol       = "TCP"
    description    = "Allow SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  # Outgoing traffic
  egress {
    protocol       = "ANY"
    description    = "Allow all outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "yandex_iam_service_account" "ig-sa" {
  name = "lamp-instance-group-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "ig-compute-admin" {
  folder_id = var.folder_id
  role      = "compute.admin"
  member    = "serviceAccount:${yandex_iam_service_account.ig-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "ig-vpc-user" {
  folder_id = var.folder_id
  role      = "vpc.user"
  member    = "serviceAccount:${yandex_iam_service_account.ig-sa.id}"
}
