output "resource_group_name" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.rg.name
}

output "vm_name" {
  description = "Name of the Windows Virtual Machine"
  value       = azurerm_windows_virtual_machine.vm.name
}

output "vm_id" {
  description = "ID of the Windows Virtual Machine"
  value       = azurerm_windows_virtual_machine.vm.id
}

output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.vm_nic.private_ip_address
}

output "vm_public_ip" {
  description = "Public IP address of the VM (for RDP access)"
  value       = azurerm_public_ip.vm_pip.ip_address
}

output "rdp_connection_string" {
  description = "RDP connection string"
  value       = "RDP to ${azurerm_public_ip.vm_pip.ip_address}:3389"
}

output "vm_size" {
  description = "Size of the Virtual Machine"
  value       = azurerm_windows_virtual_machine.vm.size
}

output "vm_admin_username" {
  description = "Admin username for RDP connection"
  value       = azurerm_windows_virtual_machine.vm.admin_username
}

output "admin_password_hint" {
  description = "Password is set in variables.tf (admin_password)"
  value       = "Use the admin_password variable value to connect via RDP"
  sensitive   = true
}

output "ansible_inventory_entry" {
  description = "Entry for Ansible inventory file"
  value       = "[windows_vms]\n${azurerm_public_ip.vm_pip.ip_address} ansible_user=${var.ansible_user} ansible_password='${var.admin_password}' ansible_connection=winrm ansible_winrm_server_cert_validation=ignore"
  sensitive   = true
}

output "network_interface_id" {
  description = "ID of the Network Interface"
  value       = azurerm_network_interface.vm_nic.id
}

output "nsg_id" {
  description = "ID of the Network Security Group"
  value       = azurerm_network_security_group.vm_nsg.id
}

output "next_steps" {
  description = "Next steps for configuring the VM"
  value       = <<-EOT
    
    1. RDP Connection:
       - Server: ${azurerm_public_ip.vm_pip.ip_address}
       - Username: ${azurerm_windows_virtual_machine.vm.admin_username}
       - Password: (see terraform output)
    
    2. Run Ansible Playbook:
       ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/main.yml
    
    3. Verify installations with Ansible:
       ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/verify.yml
    
    4. Important Notes:
       - Update 'rdp_source_ip' variable to restrict RDP access to your IP
       - Store admin_password in environment variable or AWS Secrets Manager
       - Modify source_code_path in variables.tf with your actual source code location
  EOT
}
