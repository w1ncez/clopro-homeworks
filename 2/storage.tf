resource "yandex_storage_bucket" "site_bucket" {
  bucket        = "w1nce-lamp-site-2026"
  force_destroy = true

  anonymous_access_flags {
    read        = true
    list        = false
    config_read = false
  }
}

resource "yandex_storage_object" "site_image" {
  bucket       = yandex_storage_bucket.site_bucket.bucket
  key          = "image.jpg"
  source       = "${path.module}/image.jpg"
  content_type = "image/jpeg"
}

output "image_url" {
  value = "https://storage.yandexcloud.net/${yandex_storage_bucket.site_bucket.bucket}/${yandex_storage_object.site_image.key}"
}
