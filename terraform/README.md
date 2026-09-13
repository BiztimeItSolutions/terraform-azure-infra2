# hawapay Security Testing Infrastructure - Terraform Configuration

## Overview

This Terraform configuration creates a Windows Virtual Machine on Azure with the following specifications:

- **OS**: Windows Server 2022
- **Size**: Standard_D4s_v3 (4 vCPUs, 16 GB RAM)
- **Location**: UAE North (uaenorth)
- **Pre-configured Tools**: 
  - Fortify Scan (for security analysis)
  - Sublime Text (for code review)
  - RDP optimized for remote access
  - Source code deployment directory

## Prerequisites

1. **Terraform**: Version >= 1.0
2. **Azure CLI**: Installed and authenticated
3. **Azure Subscription**: Active subscription with contributor permissions
4. **Azure AD Credentials**: Tenant ID and Subscription ID

## Required Azure Details

The following details are already configured in `terraform.tfvars`:

```
Subscription ID: 45fe6665-645e-4962-8eee-c409ea03a5r8
Tenant ID: c8707d51-da13-42f0-9c86-c847b5a1c4ca
Resource Group: rg-hawapay-test
Location: uaenorth (UAE North)
Virtual Network: vnet-hawapay-test
Subnet: vm-app
```

## Project Structure

```
terraform/
├── provider.tf           # Azure provider configuration
├── variables.tf          # Variable definitions
├── main.tf              # VM and networking resources
├── outputs.tf           # Output values
└── terraform.tfvars     # Variable values (contains sensitive data)
```

## Configuration Files

### provider.tf
- Defines Azure provider
- Sets up subscription ID and tenant ID
- Configures authentication

### variables.tf
Contains all configurable variables:
- `azure_subscription_id` - Azure subscription ID
- `azure_tenant_id` - Azure AD tenant ID
- `resource_group_name` - Target resource group
- `location` - Azure region
- `vm_name` - Virtual machine name
- `vm_size` - VM instance type (16GB RAM = Standard_D4s_v3)
- `admin_username` - RDP admin user
- `admin_password` - RDP admin password (CHANGE THIS!)
- `rdp_source_ip` - Allowed source IP for RDP (default: "*")
- `vnet_name` - Virtual network name
- `subnet_name` - Subnet name

### main.tf
Manages:
- Network Security Group (NSG)
  - RDP access (port 3389)
  - WinRM access (ports 5985-5986)
  - All other traffic denied
- Network Interface (NIC)
- Public IP address
- Windows Virtual Machine
- VM Extensions:
  - WinRM configuration for Ansible
  - Ansible provisioner
  - Diagnostics (optional)

### outputs.tf
Displays after deployment:
- VM public IP address
- RDP connection string
- VM admin username
- Ansible inventory entry
- Network details
- Next steps

### terraform.tfvars
Contains actual values for variables. **IMPORTANT**: Change sensitive values!

## Important Security Notes

### 1. Change Admin Password
Edit `terraform.tfvars`:
```hcl
admin_password = "YourSecurePassword123!" # ✓ Change this!
```

Requirements:
- Minimum 12 characters
- Uppercase letters
- Lowercase letters
- Numbers
- Special characters

### 2. Restrict RDP Access
Edit `terraform.tfvars`:
```hcl
rdp_source_ip = "2.49.1.207" # ✓ Change to your IP
```

Do NOT use "*" in production.

### 3. Sensitive Data Management
Option 1: Use environment variable
```bash
export TF_VAR_admin_password="YourSecurePassword"
terraform apply
```

Option 2: Use terraform.tfvars.local (gitignored)
```bash
cp terraform.tfvars terraform.tfvars.local
# Edit terraform.tfvars.local with real values
terraform apply -var-file="terraform.tfvars.local"
```

Option 3: Use Azure Key Vault
```bash
terraform apply -var admin_password=$(az keyvault secret show --vault-name MyKeyVault --name VmPassword --query value -o tsv)
```

## Deployment Steps

### 1. Initialize Terraform
```bash
cd terraform/
terraform init
```

### 2. Review Plan
```bash
terraform plan -out=tfplan
```

This will show all resources to be created.

### 3. Apply Configuration
```bash
terraform apply tfplan
```

### 4. Capture Outputs
After successful deployment, capture the outputs:
```bash
terraform output

# Or specific outputs:
terraform output vm_public_ip
terraform output rdp_connection_string
terraform output ansible_inventory_entry
```

## Post-Deployment

### 1. Test RDP Connection
```bash
# On Windows
mstsc.exe  # Open Remote Desktop Connection
# Connect to: <public_ip>:3389

# On macOS/Linux
rdesktop -u azureuser -p 'YourPassword' <public_ip>:3389
```

### 2. Run Ansible Playbook
```bash
cd ../ansible
ansible-playbook -i inventory/hosts.ini playbooks/main.yml
```

### 3. Verify Configuration
```bash
ansible-playbook -i inventory/hosts.ini playbooks/verify.yml
```

## Common Terraform Commands

```bash
# Reformat configuration files
terraform fmt

# Validate configuration
terraform validate

# Show state
terraform state list
terraform state show azurerm_windows_virtual_machine.vm

# Destroy resources
terraform destroy
```

## Troubleshooting

### Authentication Issues
```bash
# Re-authenticate with Azure
az login
az account set --subscription "45fe6665-645e-4962-8eee-c409ea03a5r8"
```

### Resource Group Not Found
Ensure the resource group exists:
```bash
az group show --name rg-hawapay-test
# If not found, create it:
az group create --name rg-hawapay-test --location uaenorth
```

### Virtual Network Not Found
Ensure the vnet and subnet exist:
```bash
az network vnet show --name vnet-hawapay-test --resource-group rg-hawapay-test
az network vnet subnet show --vnet-name vnet-hawapay-test --name vm-app --resource-group rg-hawapay-test
```

### RDP Connection Issues
1. Check NSG rules allow RDP (port 3389)
2. Verify VM is running
3. Wait 5 minutes after deployment for services to start
4. Check firewall rules on the VM

### Ansible Connection Issues
1. Ensure WinRM extension deployed successfully
2. Check WinRM listeners: `Get-Item -Path WSMan:\localhost\Listener`
3. Update inventory with correct IP and credentials

## Scaling and Modifications

### Change VM Size
Edit `terraform.tfvars`:
```hcl
vm_size = "Standard_D8s_v3"  # 8 vCPUs, 32 GB RAM
```

### Add Additional NICs
Edit `main.tf` - Add another network interface attachment

### Add Data Disk
Add to `main.tf`:
```hcl
resource "azurerm_managed_disk" "data_disk" {
  name                 = "vm-hawapay-data-disk"
  resource_group_name  = data.azurerm_resource_group.rg.name
  location             = data.azurerm_resource_group.rg.location
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 256
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attach" {
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  lun                = 0
  caching            = "ReadWrite"
}
```

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

This will:
- Delete the VM
- Delete the public IP
- Delete the network interface
- Delete the NSG
- Keep the resource group, vnet, and subnet (as they were created separately)

## Support and Documentation

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Terraform Examples](https://github.com/Azure-Samples/terraform-samples)
- [Azure CLI Documentation](https://docs.microsoft.com/cli/azure/)

## Next Steps

1. Deploy Terraform infrastructure
2. Run Ansible playbooks for software configuration
3. Upload Fortify license file
4. Add source code to desktop
5. Run Fortify Scan
6. Build mobile applications
