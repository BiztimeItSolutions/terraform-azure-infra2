# hawapay Security Testing Infrastructure - Ansible Configuration

## Overview

Ansible playbooks automate the configuration and installation of software on the Windows VM created by Terraform:

- **Fortify Scan**: Security static analysis tool
- **Sublime Text**: Code editor for source code review
- **Source Code**: Automatic deployment to desktop
- **RDP Optimization**: Performance tuning for remote sessions

## Architecture

```
ansible/
├── inventory/
│   └── hosts.ini              # Host inventory and variables
├── playbooks/
│   ├── main.yml               # Main configuration playbook
│   └── verify.yml             # Verification playbook
└── roles/
    ├── common-setup/          # Windows updates, packages, PowerShell
    ├── fortify-scan/          # Fortify Scan installation and setup
    ├── sublime-text/          # Sublime Text installation and config
    ├── source-code-deployment/# Source code deployment
    └── rdp-optimization/      # RDP performance tuning
```

## Prerequisites

### On Control Machine (Linux/macOS)

1. **Ansible**: Version >= 2.9
   ```bash
   pip install ansible
   ```

2. **Python WinRM**: For Windows connectivity
   ```bash
   pip install pywinrm[credssp]
   ```

3. **Ansible Galaxy Collections**:
   ```bash
   ansible-galaxy collection install community.windows
   ```

### On Target Machine (Windows VM)

- PowerShell 5.1+
- WinRM enabled (done by Terraform)
- Network connectivity to Ansible controller

## Installation and Setup

### 1. Install Ansible on Control Machine

**Ubuntu/Debian**:
```bash
sudo apt-get install python3-pip
pip3 install ansible pywinrm[credssp]
```

**macOS**:
```bash
brew install ansible
pip3 install pywinrm[credssp]
```

**Windows (using WSL)**:
```bash
wsl apt-get install python3-pip
pip3 install ansible pywinrm[credssp]
```

### 2. Install Required Collections

```bash
ansible-galaxy collection install community.windows
ansible-galaxy collection install ansible.windows
```

Or from file:
```bash
ansible-galaxy collection install -r requirements.yml
```

### 3. Update Inventory

Edit `ansible/inventory/hosts.ini`:

```ini
[windows_vms]
hawapay-scan ansible_host=<PUBLIC_IP> ansible_user=azureuser ansible_password='<PASSWORD>' ansible_connection=winrm ansible_winrm_server_cert_validation=ignore

[windows_vms:vars]
ansible_connection=winrm
ansible_winrm_server_cert_validation=ignore
ansible_port=5985
```

Replace:
- `<PUBLIC_IP>`: From Terraform output `vm_public_ip`
- `<PASSWORD>`: The admin password set in terraform.tfvars

### 4. Verify Connectivity

```bash
ansible all -i inventory/hosts.ini -m win_ping
```

Expected output:
```
hawapay-scan | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## Role Descriptions

### 1. common-setup

**Purpose**: Basic Windows configuration

**Tasks**:
- Install Windows updates
- Install Chocolatey package manager
- Install Git, 7zip
- Configure PowerShell execution policy
- Enable WinRM
- Create required directories
- Configure RDP

**Variables**:
- `ansible_user`: Windows username
- `ansible_password`: Windows password

### 2. fortify-scan

**Purpose**: Install and configure Fortify Static Analysis Scanner

**Tasks**:
- Extract Fortify installer from `C:\temp\fortify-installer.zip`
- Run installer to `C:\Fortify`
- Configure Fortify environment variables
- Create scan script template
- Verify installation

**Requirements**:
- Fortify installation file uploaded to `C:\temp\fortify-installer.zip`
- License file: `C:\Fortify\license.dat` (manual placement)

**Usage**:
```bash
# Basic scan
C:\Fortify\bin\sourceanalyzer.exe -b MyProject C:\Users\azureuser\Desktop\SourceCode
C:\Fortify\bin\sourceanalyzer.exe -b MyProject -translate
C:\Fortify\bin\sourceanalyzer.exe -b MyProject -scan

# Or use provided script
C:\Fortify\scan-source-code.ps1 -BuildName MyProject
```

### 3. sublime-text

**Purpose**: Install Sublime Text 3 and configure

**Tasks**:
- Install Sublime Text using Chocolatey
- Create configuration file
- Add to PATH
- Create desktop shortcut

**Configuration Location**:
- `C:\Program Files\Sublime Text\`
- Config: `C:\Users\azureuser\AppData\Roaming\Sublime Text 3\Packages\User\`

**Usage**:
```bash
sublime                    # Launch Sublime
sublime <filename>         # Open file
sublime -p <project>       # Open project
```

### 4. source-code-deployment

**Purpose**: Deploy source code to desktop for analysis

**Tasks**:
- Create `C:\Users\azureuser\Desktop\SourceCode` directory
- Download source code (if URL provided)
- Extract archives (ZIP, 7z, RAR, etc.)
- Create file index
- Generate deployment information

**Configuration**:
Edit `ansible/playbooks/main.yml`:
```yaml
roles:
  - role: source-code-deployment
    vars:
      source_code_url: "https://example.com/source-code.zip"  # Optional
      source_code_path: "/local/path/to/source"               # Optional
```

**Features**:
- Automatic ZIP extraction
- 7zip support for other formats
- File inventory generation
- Deployment info file

### 5. rdp-optimization

**Purpose**: Optimize RDP performance and security

**Tasks**:
- Configure connection timeouts
- Enable network-level authentication
- Set encryption level
- Configure clipboard sharing
- Enable drive redirection
- Create diagnostic script

**Diagnostic Script**:
```bash
PowerShell -ExecutionPolicy Bypass -File C:\Windows\System32\rdp-diagnostic.ps1
```

## Running Playbooks

### Run Main Configuration Playbook

```bash
cd ansible/
ansible-playbook -i inventory/hosts.ini playbooks/main.yml
```

**Options**:
```bash
# Run with extra verbosity
ansible-playbook -i inventory/hosts.ini playbooks/main.yml -vvv

# Run specific tags only
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --tags fortify

# Run specific role
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --tags common

# Dry run (check mode)
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --check

# Skip handlers (no reboot)
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --skip-tags reboot
```

### Run Verification Playbook

```bash
ansible-playbook -i inventory/hosts.ini playbooks/verify.yml
```

This playbook:
- Verifies all installations
- Checks service status
- Validates RDP configuration
- Generates verification report
- Outputs system information

### Run Specific Tags

```bash
# Install only Fortify
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --tags fortify

# Install only Sublime
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --tags sublime

# Setup common dependencies
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --tags common

# Deploy source code
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --tags sourcecode

# Configure RDP
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --tags rdp
```

## Uploading Fortify Installer

### Option 1: Via RDP
1. Connect to VM via RDP
2. Copy `FortifyInstaller.zip` to `C:\temp\fortify-installer.zip`

### Option 2: Via Azure Storage (Advanced)
```bash
# Upload to storage account
az storage blob upload --file fortify-installer.zip \
  --container-name uploads \
  --name fortify-installer.zip
```

### Option 3: Modify Ansible Role
Edit `ansible/roles/fortify-scan/tasks/main.yml`:
```yaml
- name: Download Fortify installer
  win_get_url:
    url: "https://your-storage-account.blob.core.windows.net/uploads/fortify-installer.zip"
    dest: "C:\\temp\\fortify-installer.zip"
```

## Deploying Source Code

### Option 1: Upload via RDP
```bash
1. Connect via RDP
2. Copy source code to C:\Users\azureuser\Desktop\SourceCode
```

### Option 2: Specify URL in Playbook
Edit `ansible/playbooks/main.yml`:
```yaml
roles:
  - role: source-code-deployment
    vars:
      source_code_url: "https://github.com/your-repo/archive/main.zip"
```

### Option 3: Clone from Git
Connect via RDP and run:
```bash
cd C:\Users\azureuser\Desktop\SourceCode
git clone https://github.com/your-repo.git
```

## Troubleshooting

### WinRM Connection Issues

```bash
# Test connectivity
ansible all -i inventory/hosts.ini -m win_ping -vvv

# Check WinRM status on VM (via RDP)
Get-Item -Path WSMan:\localhost\Listener
Get-PSSessionConfiguration
```

### Enable WinRM (if needed)
On VM via PowerShell (as admin):
```powershell
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\MaxEnvelopeSizeKb 4096
New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
```

### Certificate Issues
If you get certificate errors:

```bash
# Option 1: Disable cert validation (less secure)
# Edit inventory to use: ansible_winrm_server_cert_validation=ignore

# Option 2: Fix certificate (secure)
# Run as Admin on VM:
$thumbprint = (Get-ChildItem Cert:\LocalMachine\My | Select-Object -First 1).Thumbprint
New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $thumbprint -Force
```

### Playbook Errors

```bash
# Run with debug output
ansible-playbook -i inventory/hosts.ini playbooks/main.yml -vvv

# Check syntax
ansible-playbook --syntax-check playbooks/main.yml

# Dry run (no changes)
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --check
```

## Advanced Configuration

### Custom Variables

Create `ansible/group_vars/windows_vms.yml`:
```yaml
fortify_path: "C:\\Fortify"
sublime_path: "C:\\Program Files\\Sublime Text"
source_code_path: "C:\\Users\\{{ ansible_user }}\\Desktop\\SourceCode"
```

### Custom Inventory

Use dynamic inventory from Terraform:
```bash
# Generate from Terraform output
terraform output -json | jq '.ansible_inventory_entry.value' > ansible/inventory/hosts
```

### Idempotent Playbooks

All playbooks are designed to be idempotent:
```bash
# Safe to run multiple times
ansible-playbook -i inventory/hosts.ini playbooks/main.yml
ansible-playbook -i inventory/hosts.ini playbooks/main.yml  # Same result
```

## Performance Tuning

### Reduce Async Tasks
Edit playbooks to reduce `async` timeout for faster execution

### Parallel Execution
Run against multiple hosts:
```bash
ansible-playbook -i inventory/hosts.ini playbooks/main.yml -f 5
```

## Monitoring and Logging

### Enable Ansible Logging
```bash
export ANSIBLE_LOG_PATH=./ansible.log
ansible-playbook -i inventory/hosts.ini playbooks/main.yml
```

### Check VM Logs via RDP
```powershell
# Application events
Get-EventLog -LogName Application -Newest 50

# System events
Get-EventLog -LogName System -Newest 50
```

## Next Steps

1. ✓ Deploy Terraform infrastructure
2. ✓ Configure Ansible inventory
3. ✓ Run main playbook
4. ✓ Verify installations
5. Upload Fortify license
6. Add source code
7. Run Fortify Scan
8. Build mobile apps

## Support

For issues or questions:
1. Check Ansible logs: `ansible.log`
2. Review VM event logs via RDP
3. Verify network connectivity
4. Check WinRM configuration
