variable "django_secret_key" {
  type        = string
  description = "The secret cryptokey for Django production execution"
  sensitive   = true
}

variable "postgres_db_password" {
  type        = string
  description = "The master password for the sidecar PostgreSQL database"
  sensitive   = true
}