ui            = true
disable_mlock = false

storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  # TLS disabled for local dev. In production, set tls_disable = "false" and mount certs.
  tls_disable = "true"
}

# For production, enable audit devices and configure auto-unseal (AWS KMS, GCP KMS, Azure Key Vault, Transit)
# audit "file" {
#   file_path = "/vault/logs/audit.log"
# }
