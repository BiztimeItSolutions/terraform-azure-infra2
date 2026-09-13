# hawapay Infrastructure Deployment Guide

Complete step-by-step guide for deploying the hawapay security testing infrastructure.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Pre-Deployment](#pre-deployment)
3. [Terraform Deployment](#terraform-deployment)
4. [Ansible Configuration](#ansible-configuration)
5. [Verification](#verification)
6. [Post-Deployment](#post-deployment)

## Prerequisites

### Software Requirements
- **OS**: Linux, macOS, or Windows (with WSL)
- **Terraform**: v1.0 or higher
- **Ansible**: v2.9 or higher
- **Python**: 3.8 or higher
- **Azure CLI**: Latest version
- **Git**: Latest version
- **Internet**: Stable connection for Azure API calls

### Azure Requirements
- Active Azure subscription
- Appropriate permissions (Contributor role minimum)
- Service Principal or User Account
- Target resource group already created

### User Requirements
- Administrative access on Windows VM after deployment
- RDP client installed for remote desktop
- Basic knowledge of Terraform and Ansible
- Access to Fortify installation file

## Pre-Deployment

### 1. Clone Repository
```bash
git clone <repository-url>
cd terraform
```

### 2. Install Dependencies

**On Linux/macOS**:
```bash
# Install Ansible
pip3 install -r requirements.txt

# Install Ansible collections
ansible-galaxy install -r ansible/requirements.yml
```

**On Windows (PowerShell)**:
```powershell
# Install Python if needed
# Then run:
pip install -r requirements.txt
ansible-galaxy install -r ansible/requirements.yml
```

### 3. Authenticate with Azure

```bash
# Login to Azure
az login

# Select subscription
az account set --subscription "11fe1111-11e-1111-1111-11111ea011111"

# Verify subscription
az account show
```

**Expected output**:
```json
{
  "id": "11fe1111-11e-1111-1111-11111ea011111",
  "name": "test",
  "state": "Enabled",
  "tenantId": "c8707d51-da13-42f0-9c86-c847b5a1c4ca"
}
```

### 4. Verify Azure Resources

```bash
# Check resource group
az group show --name rg-hawapay-test

# Check virtual network
az network vnet show --name vnet-hawapay-test --resource-group rg-hawapay-test

# Check subnet
az network vnet subnet show \
  --vnet-name vnet-hawapay-test \
  --name vm-app \
  --resource-group rg-hawapay-test
```

### 5. Configure Terraform Variables

```bash
cd terraform/

# Copy example file
cp terraform.tfvars terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Critical changes**:
```hcl
# CHANGE THIS PASSWORD
admin_password = "YourSecurePassword123!"

# RESTRICT RDP ACCESS TO YOUR IP
rdp_source_ip = "YOUR.IP.ADDRESS/32"

# Verify subscription and tenant
azure_subscription_id = "11fe1111-11e-1111-1111-11111ea011111"
azure_tenant_id       = "c8707d51-da13-42f0-9c86-c847b5a1c4ca"
```

### 6. Prepare Source Code (Optional)

If deploying source code automatically:
```bash
# Create directory
mkdir -p ~/source-code

# Copy your source code here
cp -r /path/to/your/source/* ~/source-code/

# Update terraform.tfvars
# source_code_path = "/home/user/source-code"
```

## Terraform Deployment

### Step 1: Initialize Terraform

```bash
cd terraform/

# Initialize working directory
terraform init

# Output should show:
# - Terraform has been successfully configured!
# - Provider hashicorp/azurerm version ...
```

### Step 2: Validate Configuration

```bash
# Validate Terraform files
terraform validate

# Format Terraform files
terraform fmt -recursive

# Lint check (optional)
terraform fmt -check
```

### Step 3: Plan Deployment

```bash
# Create execution plan
terraform plan -out=tfplan

# Review the output for:
# - Resources to be created
# - Network configuration
# - VM specifications
# - Security groups

# Save plan to file
terraform show tfplan > deployment-plan.txt
```

**Expected output**:
```
Plan: 7 to add, 0 to change, 0 to destroy.

Resources to be created:
- azurerm_network_security_group
- azurerm_public_ip
- azurerm_network_interface
- azurerm_network_interface_security_group_association
- azurerm_windows_virtual_machine
- azurerm_virtual_machine_extension (winrm)
- azurerm_virtual_machine_extension (ansible_provisioner)
```

### Step 4: Apply Deployment

```bash
# Apply the plan
terraform apply tfplan

# Wait for completion (5-10 minutes typically)
# Watch for status messages:
# - azurerm_public_ip.vm_pip: Creation complete
# - azurerm_windows_virtual_machine.vm: Creation complete
```

### Step 5: Capture Outputs

```bash
# Display all outputs
terraform output

# Save outputs to file
terraform output > deployment-output.txt

# Capture specific outputs
PUBLIC_IP=$(terraform output -raw vm_public_ip)
echo "Public IP: $PUBLIC_IP"

# Save for next steps
echo "PUBLIC_IP=$PUBLIC_IP" >> deployment-vars.env
```

**Key outputs to save**:
- `vm_public_ip` - For RDP and Ansible
- `rdp_connection_string` - Connection details
- `ansible_inventory_entry` - For Ansible inventory

### Step 6: Verify Infrastructure

```bash
# Check VM is running
az vm show --name vm-hawapay-scan-test --resource-group rg-hawapay-test --query "powerState" -o tsv

# Get public IP
PUBLIC_IP=$(az vm show -d --name vm-hawapay-scan-test --resource-group rg-hawapay-test --query "publicIps" -o tsv)
echo "VM Public IP: $PUBLIC_IP"

# Check network security group
az network nsg show --name hawapay-vm-nsg-test --resource-group rg-hawapay-test
```

## Ansible Configuration

### Step 1: Wait for VM Initialization

```bash
# Wait 5 minutes for Windows services to start
echo "Waiting for VM to initialize..."
sleep 300

# Test RDP accessibility
nc -zv $PUBLIC_IP 3389
```

### Step 2: Update Ansible Inventory

```bash
cd ../ansible/

# Edit inventory file
nano inventory/hosts.ini
```

**Update with Terraform outputs**:
```ini
[windows_vms]
hawapay-scan ansible_host=<PUBLIC_IP> \
  ansible_user=azureuser \
  ansible_password='<PASSWORD>' \
  ansible_connection=winrm \
  ansible_winrm_server_cert_validation=ignore

[windows_vms:vars]
ansible_connection=winrm
ansible_winrm_server_cert_validation=ignore
ansible_port=5985
```

### Step 3: Verify Connectivity

```bash
# Test Ansible connectivity
ansible all -i inventory/hosts.ini -m win_ping

# Expected output:
# hawapay-scan | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

If connectivity fails:
1. Wait 2 more minutes for WinRM service
2. Verify firewall allows port 5985
3. Check credentials in inventory
4. See troubleshooting section

### Step 4: Run Main Playbook

```bash
# Dry run first (no changes)
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --check

# Run with verbose output
ansible-playbook -i inventory/hosts.ini playbooks/main.yml -vv

# Full run (takes 15-30 minutes)
ansible-playbook -i inventory/hosts.ini playbooks/main.yml
```

**Monitor output for**:
- common-setup: Windows updates, Chocolatey installation
- fortify-scan: Fortify installation
- sublime-text: Sublime Text setup
- source-code-deployment: Source code placement
- rdp-optimization: RDP configuration

### Step 5: Run Verification Playbook

```bash
# Verify all installations
ansible-playbook -i inventory/hosts.ini playbooks/verify.yml

# Generates verification report on desktop
# Check: C:\Users\azureuser\Desktop\VERIFICATION_REPORT.txt
```

## Verification

### Step 1: RDP Connection

```bash
# Connect via RDP
# Address: <PUBLIC_IP>:3389
# Username: azureuser
# Password: (from terraform.tfvars)

# On Linux/macOS:
rdesktop -u azureuser -p 'password' $PUBLIC_IP:3389

# On Windows:
mstsc.exe  # Open Remote Desktop Connection
```

### Step 2: Verify Installations (via RDP)

**In PowerShell**:
```powershell
# Check Fortify
Test-Path "C:\Fortify\bin\sourceanalyzer.exe"

# Check Sublime Text
Test-Path "C:\Program Files\Sublime Text\subl.exe"

# Check source code directory
Get-ChildItem "C:\Users\azureuser\Desktop\SourceCode"

# Check RDP service
Get-Service TermService

# View verification report
Get-Content "C:\Users\azureuser\Desktop\VERIFICATION_REPORT.txt"
```

### Step 3: System Requirements Check

```powershell
# Get system info
systeminfo

# Check RAM (should be ~16 GB)
$memory = Get-ComputerInfo | Select-Object CsPhysicalMemory
[math]::Round($memory.CsPhysicalMemory / 1GB, 2)

# Check disk space
Get-Volume C:
```

## Post-Deployment

### Step 1: Upload Fortify License

```bash
# Via RDP:
# 1. Copy license.dat to C:\Fortify\

# Or via Ansible:
# (If you have license file locally)
```

### Step 2: Deploy Source Code

```bash
# Via RDP:
# Copy source code to: C:\Users\azureuser\Desktop\SourceCode

# Via Git (if available):
# cd C:\Users\azureuser\Desktop\SourceCode
# git clone <repo-url>

# Via Ansible (if URL available):
# Update ansible/playbooks/main.yml with source code URL
# Re-run source code deployment role
```

### Step 3: Initial Fortify Scan

```powershell
# In PowerShell on VM:
C:\Fortify\bin\sourceanalyzer.exe -b TestProject C:\Users\azureuser\Desktop\SourceCode
C:\Fortify\bin\sourceanalyzer.exe -b TestProject -translate
C:\Fortify\bin\sourceanalyzer.exe -b TestProject -scan
```

### Step 4: Mobile App Development

**Create build variants**:
1. Android with SSL Pinning + Jailbreak Detection
2. Android without SSL Pinning, no Jailbreak Detection
3. iOS with SSL Pinning + Root Detection
4. iOS without SSL Pinning, no Root Detection

Build environment:
- Android Studio: Pre-install recommended
- Xcode: Setup required on macOS
- Source code: Available at C:\Users\azureuser\Desktop\SourceCode

### Step 5: Enable Monitoring

```bash
# In Azure Portal:
# VM → Monitoring → Diagnostics Settings
# Enable diagnostics for performance monitoring
```

### Step 6: Document Configuration

```bash
# Create deployment summary
cat > deployment-summary.md <<EOF
# Deployment Summary

- **Date**: $(date)
- **VM**: vm-hawapay-scan-test
- **Public IP**: $PUBLIC_IP
- **Region**: uaenorth
- **Resource Group**: rg-hawapay-test
- **Admin User**: azureuser
- **Status**: Deployed

## Installed Software
- Fortify Scan: C:\Fortify
- Sublime Text: C:\Program Files\Sublime Text
- Git: System PATH
- 7-Zip: C:\Program Files\7-Zip

## Source Code
- Location: C:\Users\azureuser\Desktop\SourceCode
- Status: Ready for deployment

## Next Steps
1. Upload Fortify license
2. Add source code
3. Run Fortify Scan
4. Build mobile apps
EOF
```

## Rollback Procedure

If deployment needs to be undone:

```bash
# Destroy Terraform resources
cd terraform/
terraform destroy

# Confirm destruction
# Type: yes

# Verify deletion
az vm show --name vm-hawapay-scan-test --resource-group rg-hawapay-test 2>&1 | grep -i "not found"
```

## Deployment Checklist

- [ ] Azure login verified
- [ ] Dependencies installed
- [ ] terraform.tfvars configured
- [ ] Terraform initialized
- [ ] Terraform plan reviewed
- [ ] Terraform applied successfully
- [ ] VM created and running
- [ ] Public IP obtained
- [ ] Ansible inventory updated
- [ ] Ansible connectivity verified
- [ ] Main playbook executed
- [ ] Verification playbook passed
- [ ] RDP connection tested
- [ ] All software verified installed
- [ ] Source code location ready
- [ ] Fortify scan ready
- [ ] Mobile build environment ready

## Troubleshooting

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues.

## Support

For issues or questions:
1. Check Ansible logs: `ansible.log`
2. Review Terraform logs
3. Check Azure Portal for errors
4. Verify network connectivity
5. Review security group rules

## Deployment Time Estimate

| Phase | Duration |
|-------|----------|
| Terraform planning | 2 minutes |
| Terraform apply | 5-10 minutes |
| VM initialization | 5 minutes |
| Ansible run | 15-30 minutes |
| Verification | 5 minutes |
| **Total** | **30-50 minutes** |

---

**Last Updated**: 2024
**Version**: 1.0
