variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  default     = "45fe6665-645e-4962-8eee-c409ea03a5r8"
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  default     = "c8707d51-da13-42f0-9c86-c847b5a1c4ca" # Update with your actual tenant ID
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-hawapay-test"
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "uaenorth"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "test"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "hawapay"
}

# VM Configuration
variable "vm_name" {
  description = "Name of the Windows VM"
  type        = string
  default     = "vm-hawapay-scan-test"
}

variable "vm_size" {
  description = "Size of the Virtual Machine - D4s_v3 provides 4 cores and 16 GB RAM"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "vm_os_publisher" {
  description = "Publisher of the OS image"
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "vm_os_offer" {
  description = "Offer of the OS image"
  type        = string
  default     = "WindowsServer"
}

variable "vm_os_sku" {
  description = "SKU of the Windows OS"
  type        = string
  default     = "2022-datacenter-g2"
}

variable "vm_os_version" {
  description = "Version of the OS image"
  type        = string
  default     = "Latest"
}

# Network Configuration
variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
  default     = "vnet-hawapay-test"
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "vm-app"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "Address prefix for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# RDP Access
variable "rdp_source_ip" {
  description = "Source IP for RDP access (set to your IP for security)"
  type        = string
  default     = "*" # IMPORTANT: Restrict this to your IP in production
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the VM (minimum 12 characters, uppercase, lowercase, digit, special char)"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd1234!" # Change this to a secure password
}

# Tags
variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default = {
    Environment = "test"
    Project     = "hawapay"
    ManagedBy   = "Terraform"
    Purpose     = "Security Scanning & Mobile Testing"
  }
}

# Ansible Configuration
variable "ansible_user" {
  description = "Ansible user for configuration management"
  type        = string
  default     = "azureuser"
}

variable "source_code_path" {
  description = "Path or URL to source code to be deployed"
  type        = string
  default     = "" # Provide the path or URL to your source code
}

variable "enable_diagnostics" {
  description = "Enable Azure diagnostics for the VM"
  type        = bool
  default     = true
}
