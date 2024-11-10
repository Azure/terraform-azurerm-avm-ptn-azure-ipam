resource "random_string" "name" {
  length  = 6
  special = false
  upper   = false
}

output "name" {
  value = random_string.name.result
}