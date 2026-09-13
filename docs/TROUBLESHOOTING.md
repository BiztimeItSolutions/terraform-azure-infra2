# Troubleshooting Guide

Comprehensive troubleshooting guide for common issues during deployment and configuration.

## Table of Contents
1. [Terraform Issues](#terraform-issues)
2. [Ansible Issues](#ansible-issues)
3. [RDP Issues](#rdp-issues)
4. [Azure Issues](#azure-issues)
5. [Software Installation Issues](#software-installation-issues)

## Terraform Issues

### Issue: "Subscription not found"

**Error message**:
```
Error: retrieving subscription: subscription with name 'xxx' is not found
```

**Solution**:
```bash
# List all subscriptions
az account list --output table

# Use subscription ID directly
az account set --subscription "11fe1111-11e-1111-1111-11111ea011111"

# Verify
az account show
```

### Issue: "Authorization failed"

**Error message**:
```
authorization.AuthorizationFailed: The client 'xxx' with object id 'xxx' does not have authorization
```

**Solution**:
```bash
# Check current user
az account show

# Verify permissions in Azure Portal
# User/Group → Role Assignments → Check for Contributor role

# Or request access from Azure Admin
```

### Issue: "Resource group not found"

**Error message**:
```
Error: retrieving resource group "rg-hawapay-test": azure.BearerTokenError
```

**Solution**:
```bash
# Check if RG exists
az group show --name rg-hawapay-test

# If not found, create it
az group create --name rg-hawapay-test --location uaenorth

# Verify
az group show --name rg-hawapay-test
```

### Issue: "Virtual network not found"

**Error message**:
```
Error: retrieving Virtual Network "vnet-hawapay-test": azure.BearerTokenError
```

**Solution**:
```bash
# List all virtual networks
az network vnet list --resource-group rg-hawapay-test

# Check if VNET exists
az network vnet show --name vnet-hawapay-test --resource-group rg-hawapay-test

# If missing, create it
az network vnet create \
  --name vnet-hawapay-test \
  --resource-group rg-hawapay-test \
  --address-prefix 10.0.0.0/16

# Create subnet
az network vnet subnet create \
  --name vm-app \
  --vnet-name vnet-hawapay-test \
  --resource-group rg-hawapay-test \
  --address-prefix 10.0.1.0/24
```

### Issue: "Terraform state lock"

**Error message**:
```
Error acquiring the state lock
```

**Solution**:
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>

# Or delete lock file
rm .terraform/terraform.tfstate.*.lock.hcl

# Reinitialize
terraform init
```

### Issue: "Module not found"

**Error message**:
```
Error: Failed to download module
```

**Solution**:
```bash
# Reinitialize Terraform
cd terraform/
rm -rf .terraform/
terraform init

# Download modules explicitly
terraform get -update
```

### Issue: "Invalid variable value"

**Error message**:
```
Error: Invalid value for variable "admin_password"
```

**Solution**:
```bash
# Check password requirements:
# - Minimum 12 characters
# - Uppercase letters (A-Z)
# - Lowercase letters (a-z)
# - Numbers (0-9)
# - Special characters (!@#$%^&*)

# Update terraform.tfvars
admin_password = "P@ssw0rd1234!"
```

## Ansible Issues

### Issue: Connection timeout

**Error message**:
```
FAILED! => {
  "msg": "Request failed: (<class 'pywintypes.com_error'>, ... Timed out"
}
```

**Solution**:

```bash
# Check network connectivity
ping <PUBLIC_IP>

# Verify RDP port is open
nc -zv <PUBLIC_IP> 3389

# Wait for VM initialization (5+ minutes after deployment)
sleep 300
ansible all -i inventory/hosts.ini -m win_ping

# Check WinRM port
nc -zv <PUBLIC_IP> 5985
```

### Issue: Authentication failed

**Error message**:
```
FAILED! => {
  "msg": "WinRM authentication failure: Unauthorized"
}
```

**Solution**:

```bash
# Verify credentials in inventory
cat ansible/inventory/hosts.ini

# Check password is correct
# Escape special characters with single quotes

# Test with explicit credentials
ansible -i inventory/hosts.ini -u azureuser -k all -m win_ping

# Enter password when prompted
```

### Issue: Certificate validation error

**Error message**:
```
FAILED! => {
  "msg": "ssl: CERTIFICATE_VERIFY_FAILED"
}
```

**Solution**:

```bash
# Option 1: Disable certificate validation (in inventory)
ansible_winrm_server_cert_validation=ignore

# Option 2: Fix certificate on VM (via RDP)
# PowerShell:
$thumbprint = (Get-ChildItem Cert:\LocalMachine\My | Select-Object -First 1).Thumbprint
New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $thumbprint -Force

# Option 3: Use HTTP (not recommended)
ansible_port=5985
```

### Issue: "Collection not found"

**Error message**:
```
ERROR! couldn't resolve module/action 'community.windows.xxx'
```

**Solution**:

```bash
# Install required collections
ansible-galaxy collection install community.windows
ansible-galaxy collection install ansible.windows

# Or install from file
ansible-galaxy collection install -r ansible/requirements.yml

# List installed collections
ansible-galaxy collection list
```

### Issue: Playbook hangs

**Error message**:
```
[<hostname>] EXEC /bin/sh... (no response for 300 seconds)
```

**Solution**:

```bash
# Press Ctrl+C to stop

# Run with increased timeout
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --timeout=600

# Run specific role instead
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --tags common

# Check VM status
az vm get-instance-view --name vm-hawapay-scan-test --resource-group rg-hawapay-test --query "powerState"
```

### Issue: "Host unreachable"

**Error message**:
```
fatal: [<hostname>]: UNREACHABLE! => {
  "msg": "Host unreachable"
}
```

**Solution**:

```bash
# Test basic connectivity
ansible all -i inventory/hosts.ini -m win_ping -vvv

# Check network security group
az network nsg show --name hawapay-vm-nsg-test --resource-group rg-hawapay-test

# Verify WinRM is running (via RDP)
# PowerShell: Get-Service WinRM
# Or: winrm enumerate winrm/config/listener

# Enable WinRM if needed (via RDP PowerShell as Admin):
Enable-PSRemoting -Force
```

## RDP Issues

### Issue: "Connection refused"

**Error message**:
```
The connection was denied because the user account is not
authorized for remote login
```

**Solution**:

```bash
# Wait 2-3 minutes after Ansible playbook completes
# Or restart Remote Desktop service

# Via RDP (if you can get in):
# Services → Remote Desktop Services → Restart

# Via Azure Portal:
# VM → Run command → Restart-Service -Name TermService

# Via PowerShell from local:
az vm run-command invoke \
  --resource-group rg-hawapay-test \
  --name vm-hawapay-scan-test \
  --command-id RunPowerShellScript \
  --scripts "Restart-Service -Name TermService"
```

### Issue: "Connection timeout"

**Error message**:
```
The connection attempt timed out
```

**Solution**:

```bash
# Check if VM is running
az vm get-instance-view --name vm-hawapay-scan-test --resource-group rg-hawapay-test --query "powerState"

# Check network security group allows RDP
az network nsg rule show \
  --resource-group rg-hawapay-test \
  --nsg-name hawapay-vm-nsg-test \
  --name RDP-Inbound

# Verify your IP is in the allowed range
# Check terraform.tfvars rdp_source_ip setting

# Start VM if stopped
az vm start --resource-group rg-hawapay-test --name vm-hawapay-scan-test

# Wait for VM startup
sleep 120
```

### Issue: "Network path not found"

**Error message**:
```
Logon failure: The target account name is incorrect
```

**Solution**:

```bash
# Verify username
# Should be: azureuser (not COMPUTERNAME\azureuser)

# On macOS/Linux:
# rdesktop -u azureuser -p 'password' <PUBLIC_IP>:3389

# On Windows:
# mstsc.exe → Advanced → username: azureuser

# Wait for Windows to fully boot (5+ minutes)
```

### Issue: "Blank screen after login"

**Solution**:

```bash
# Wait 1-2 minutes for desktop to load

# Restart Explorer (if you can access it)
# Task Manager → Restart explorer.exe

# Or via PowerShell (from another admin session):
Stop-Process -Name explorer -Force
Start-Process explorer
```

## Azure Issues

### Issue: "Quota exceeded"

**Error message**:
```
Allocation failed. VM size not available
```

**Solution**:

```bash
# Check available sizes
az vm list-sizes --location uaenorth --output table

# Change VM size in terraform.tfvars
vm_size = "Standard_B4ms"  # Alternative size

# Reapply Terraform
terraform apply -var-file=terraform.tfvars
```

### Issue: "Storage account not found"

**Error message**:
```
The specified storage account does not exist
```

**Solution**:

```bash
# If using remote state storage, verify account exists
az storage account list --resource-group rg-hawapay-test

# Or create storage account
az storage account create \
  --name tfstatehawapaytest \
  --resource-group rg-hawapay-test \
  --location uaenorth
```

### Issue: "Cost exceeded"

**Solution**:

```bash
# Estimate costs
terraform plan -out=tfplan | grep -i "cost\|billing"

# Delete resources if costs are too high
terraform destroy

# Use smaller VM size
vm_size = "Standard_B2s"  # Lower cost option
```

## Software Installation Issues

### Issue: Fortify installation fails

**Error message**:
```
Fortify installation encountered an issue
```

**Solution**:

```bash
# Verify installer file exists
Test-Path "C:\temp\fortify-installer.zip"

# Extract manually
Expand-Archive -Path "C:\temp\fortify-installer.zip" -DestinationPath "C:\temp\fortify"

# Run installer manually
& 'C:\temp\fortify\FortifyInstaller.exe' /S /D=C:\Fortify

# Check logs
Get-Content "C:\ProgramData\Fortify\*.log"

# Re-run Ansible role
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --tags fortify
```

### Issue: Sublime Text not installing

**Error message**:
```
Sublime installation encountered an issue
```

**Solution**:

```bash
# Install manually via Chocolatey
choco install sublimetext3 -y

# Or download directly
# https://www.sublimetext.com/3

# Verify installation
Test-Path "C:\Program Files\Sublime Text\subl.exe"

# Re-run Ansible
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --tags sublime
```

### Issue: Source code not on desktop

**Error message**:
```
Directory C:\Users\azureuser\Desktop\SourceCode is empty
```

**Solution**:

```bash
# Option 1: Upload via RDP
# Copy files to C:\Users\azureuser\Desktop\SourceCode

# Option 2: Deploy via Ansible with URL
# Edit playbooks/main.yml
source_code_url: "https://your-url/source.zip"

# Re-run playbook
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --tags sourcecode

# Option 3: Clone from Git
cd C:\Users\azureuser\Desktop\SourceCode
git clone <repo-url>
```

## Performance Issues

### Issue: Slow RDP performance

**Solution**:

```bash
# Disconnect RDP and reconnect
# In RDP client → Display settings:
# - Reduce screen resolution
# - Reduce color depth
# - Disable themes

# Or via PowerShell:
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name EnableWindowsKey -Value 0
```

### Issue: High CPU usage

**Solution**:

```bash
# Check processes
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

# Restart services
Restart-Service -Name W3SVC -Force
Restart-Service -Name WinRM -Force

# Or restart VM
Restart-Computer
```

### Issue: Disk space low

**Solution**:

```bash
# Check disk space
Get-Volume C:

# Clean temporary files
Remove-Item C:\temp\* -Recurse -Force
Remove-Item C:\Windows\Temp\* -Recurse -Force

# Compact OS (Windows 10/11)
Optimize-Volume -DriveLetter C -Defrag -Verbose
```

## General Debugging

### Enable verbose logging

```bash
# Terraform
export TF_LOG=DEBUG
terraform plan

# Ansible
export ANSIBLE_DEBUG=1
ansible-playbook -i inventory/hosts.ini playbooks/main.yml -vvv

# Or save to file
export ANSIBLE_LOG_PATH=./debug.log
```

### Collect diagnostic information

```bash
# Terraform
terraform show -json > terraform-state.json
terraform plan -out=tfplan
terraform show tfplan > deployment-plan.txt

# Ansible
ansible all -i inventory/hosts.ini -m setup > system-facts.json

# Azure
az resource list --resource-group rg-hawapay-test > resources.json
```

### Common fixes checklist

- [ ] Wait 5+ minutes for VM initialization
- [ ] Restart Remote Desktop service
- [ ] Clear Ansible cache: `rm -rf ~/.ansible/cache/`
- [ ] Reinitialize Terraform: `rm -rf .terraform && terraform init`
- [ ] Verify network security group rules
- [ ] Check source IP against rdp_source_ip setting
- [ ] Restart VM via Azure Portal
- [ ] Disable certificate validation in Ansible inventory
- [ ] Run Ansible in check mode to identify issues

## Contacting Support

If issues persist:

1. Collect diagnostic information:
   ```bash
   terraform show > tf_state.txt
   ansible-playbook -i inventory/hosts.ini playbooks/verify.yml > verification.txt
   ```

2. Check Azure Portal for resource errors

3. Review security group rules and firewall configuration

4. Verify all credentials and permissions

5. Contact Azure support or Ansible community forums

---

**Last Updated**: 2024
**Version**: 1.0
