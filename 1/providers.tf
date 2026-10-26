terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.100"
    }
  }
  required_version = ">= 1.0"
}

provider "yandex" {
  zone                     = "ru-central1-a"
  service_account_key_file = "${SA_KEY}"
  cloud_id                 = "${CLOUD_ID}"
  folder_id                = "${FOLDER_ID}"
}
