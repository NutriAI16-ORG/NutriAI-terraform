output "vm_id" {
  value       = azurerm_linux_virtual_machine.vm.id
  description = "The ID of the virtual machine"
}

output "vm_private_ip" {
  value       = azurerm_network_interface.vm_nic.ip_configuration[0].private_ip_address
  description = "The private IP address of the jump VM"
}

output "vm_identity_principal_id" {
  value       = azurerm_linux_virtual_machine.vm.identity[0].principal_id
  description = "The principal ID of the VM's system assigned identity"
}
