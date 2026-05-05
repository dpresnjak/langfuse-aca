output "vm_id" {
  value       = azurerm_linux_virtual_machine.this.id
  description = "ClickHouse VM resource ID."
}

output "ssh_private_key_pem" {
  value       = tls_private_key.ssh.private_key_pem
  description = "Generated SSH private key for break-glass VM access."
  sensitive   = true
}
