# hawapay Security Testing Infrastructure

Complete Infrastructure-as-Code (IaC) solution for setting up a Windows VM on Azure with Fortify Scan, Sublime Text, and source code deployment capabilities.

## 🎯 Project Overview

This project automates:

1. **Infrastructure**: Azure VM creation via Terraform
   - Windows Server 2022
   - 16 GB RAM (Standard_D4s_v3)
   - Optimized for security scanning

2. **Configuration**: Software installation via Ansible
   - Fortify Scan (static security analysis)
   - Sublime Text (code editor)
   - Source code deployment
   - RDP optimization

3. **Testing**: Mobile app builds
   - Android (2 builds)
   - iOS (2 builds)
   - Configurations: With/Without SSL pinning & jailbreak/root detection

## 📋 Architecture

```
┌─────────────────────────────────────────────────────┐
│         hawapay Security Testing Infrastructure      │
└─────────────────────────────────────────────────────┘
           │
           ├─ Terraform (Infrastructure)
           │  └─ Azure VM, Networking, Security
           │
           ├─ Ansible (Configuration)
           │  ├─ Fortify Scan
           │  ├─ Sublime Text
           │  ├─ Source Code Deployment
           │  └─ RDP Optimization
           │
           └─ Mobile Testing (Manual)
              ├─ Android Builds (2)
              └─ iOS Builds (2)
```

## 📁 Project Structure

```
.
├── terraform/                 # Infrastructure as Code
│   ├── provider.tf           # Azure provider config
│   ├── variables.tf          # Variable definitions
│   ├── main.tf               # VM and networking
│   ├── outputs.tf            # Output values
│   ├── terraform.tfvars      # Configuration values
│   └── README.md             # Terraform documentation
│
├── ansible/                   # Configuration Management
│   ├── inventory/
│   │   └── hosts.ini         # Host inventory
│   ├── playbooks/
│   │   ├── main.yml          # Main configuration
│   │   └── verify.yml        # Verification
│   ├── roles/
│   │   ├── common-setup/     # Base setup
│   │   ├── fortify-scan/     # Fortify installation
│   │   ├── sublime-text/     # Sublime Text setup
│   │   ├── source-code-deployment/  # Source code
│   │   └── rdp-optimization/ # RDP tuning
│   └── README.md             # Ansible documentation
│
├── docs/                      # Documentation
│   ├── GETTING_STARTED.md    # Quick start guide
│   ├── DEPLOYMENT.md         # Deployment guide
│   └── TROUBLESHOOTING.md    # Troubleshooting
│
└── README.md                 # This file
```

## 🚀 Quick Start

### Prerequisites

- **Terraform**: >= 1.0
- **Ansible**: >= 2.9
- **Azure CLI**: Latest
- **Python**: 3.8+
- **Credentials**: Azure subscription access

### Step 1: Configure Azure

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "11fe1111-11e-1111-1111-11111ea011111"

# Verify resource group exists
az group show --name rg-hawapay-test
```

### Step 2: Deploy Infrastructure

```bash
cd terraform/

# Initialize
terraform init

# Review plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Capture outputs
terraform output
```

**Important**: Save the public IP address from outputs.

### Step 3: Update Ansible Inventory

```bash
# Edit with public IP from Terraform
nano ../ansible/inventory/hosts.ini
```

Update:
```ini
[windows_vms]
hawapay-scan ansible_host=<PUBLIC_IP> ansible_user=azureuser ansible_password='<PASSWORD>' ...
```

### Step 4: Run Ansible Playbooks

```bash
cd ../ansible/

# Test connectivity
ansible all -i inventory/hosts.ini -m win_ping

# Configure VM
ansible-playbook -i inventory/hosts.ini playbooks/main.yml

# Verify installations
ansible-playbook -i inventory/hosts.ini playbooks/verify.yml
```

### Step 5: Connect via RDP

```bash
# Get IP from Terraform output
RDP to: <PUBLIC_IP>:3389
Username: azureuser
Password: (from terraform.tfvars)
```

## 🔐 Security Considerations

### Critical: Change Default Password
Edit `terraform/terraform.tfvars`:
```hcl
admin_password = "YourStrongPassword123!"  # ✓ Change this!
```

### Critical: Restrict RDP Access
Edit `terraform/terraform.tfvars`:
```hcl
rdp_source_ip = "YOUR.IP.ADDRESS/32"  # ✓ Replace with your IP
```

### Best Practices

1. **Password Management**
   - Use environment variables
   - Store in Azure Key Vault
   - Never commit to Git

2. **Network Security**
   - Restrict RDP to specific IPs
   - Use VPN for connections
   - Monitor NSG rules

3. **Credentials**
   - Store in `.gitignore` files
   - Use managed identities
   - Rotate regularly

## 🛠️ Configuration Details

### VM Specifications

| Property | Value |
|----------|-------|
| OS | Windows Server 2022 |
| Size | Standard_D4s_v3 |
| vCPUs | 4 |
| RAM | 16 GB |
| Storage | 128 GB Premium SSD |
| Location | UAE North |
| RDP Port | 3389 |
| WinRM Port | 5985-5986 |

### Azure Resources

| Resource | Name |
|----------|------|
| Resource Group | rg-hawapay-test |
| Virtual Network | vnet-hawapay-test |
| Subnet | vm-app (10.0.1.0/24) |
| Public IP | vm-hawapay-scan-test-pip |
| Network Interface | vm-hawapay-scan-test-nic |
| NSG | hawapay-vm-nsg-test |

### Installed Software

| Software | Path | Version |
|----------|------|---------|
| Fortify Scan | C:\Fortify | Latest |
| Sublime Text | C:\Program Files\Sublime Text | 3 |
| Git | System PATH | Latest |
| 7-Zip | C:\Program Files\7-Zip | Latest |
| Chocolatey | C:\ProgramData\chocolatey | Latest |

## 📖 Detailed Documentation

### Terraform Guide
See [terraform/README.md](terraform/README.md) for:
- Detailed configuration options
- Security settings
- Advanced customization
- Troubleshooting

### Ansible Guide
See [ansible/README.md](ansible/README.md) for:
- Role descriptions
- Playbook usage
- Variable configuration
- Testing and validation

## 🔧 Common Tasks

### Deploy Infrastructure Only (Terraform)
```bash
cd terraform/
terraform apply
```

### Configure Existing VM (Ansible)
```bash
cd ansible/
ansible-playbook -i inventory/hosts.ini playbooks/main.yml
```

### Run Specific Installation
```bash
# Only Fortify
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --tags fortify

# Only Sublime
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --tags sublime

# Only source code
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --tags sourcecode
```

### Upload Fortify License
1. Connect via RDP
2. Copy `license.dat` to `C:\Fortify\license.dat`

### Add Source Code
1. Connect via RDP
2. Copy source code to `C:\Users\azureuser\Desktop\SourceCode`

### Run Fortify Scan
```bash
# Via RDP PowerShell
C:\Fortify\scan-source-code.ps1 -BuildName "MyProject"
```

### Verify Installation
```bash
ansible-playbook -i inventory/hosts.ini playbooks/verify.yml
```

### Destroy Infrastructure
```bash
cd terraform/
terraform destroy
```

## 📱 Mobile App Development

### Android Builds

**Build 1: With SSL Pinning + Jailbreak Detection**
```gradle
buildTypes {
  secureDebug {
    sslPinning = true
    jailbreakDetection = true
  }
}
```

**Build 2: Without SSL Pinning, No Jailbreak Detection**
```gradle
buildTypes {
  standardDebug {
    sslPinning = false
    jailbreakDetection = false
  }
}
```

### iOS Builds

**Build 1: With SSL Pinning + Root Detection**
```swift
#define SSL_PINNING 1
#define ROOT_DETECTION 1
```

**Build 2: Without SSL Pinning, No Root Detection**
```swift
#define SSL_PINNING 0
#define ROOT_DETECTION 0
```

## 🚨 Troubleshooting

### RDP Connection Issues
1. Wait 5 minutes after deployment
2. Check NSG allows port 3389
3. Verify source IP is in whitelist
4. Restart TermService: `Restart-Service -Name TermService`

### Ansible Connection Issues
1. Run `ansible all -i inventory/hosts.ini -m win_ping -vvv`
2. Check WinRM: `Get-PSSessionConfiguration`
3. Enable WinRM: `Enable-PSRemoting -Force`

### Fortify Installation Issues
1. Verify installer at `C:\temp\fortify-installer.zip`
2. Check disk space: `Get-Volume C:`
3. Review log: Check Application Event Log

### Source Code Not Visible
1. Check directory: `C:\Users\azureuser\Desktop\SourceCode`
2. Verify permissions: Right-click → Properties → Security
3. Refresh desktop: F5

## 📊 Monitoring

### VM Monitoring
Azure Portal → VM → Metrics

### RDP Session Monitoring
```powershell
# List sessions
quser

# Disconnect session
logoff <SESSION_ID>
```

### Service Status
```powershell
# Check services
Get-Service TermService, WinRM

# View logs
Get-EventLog -LogName Application -Newest 50
```

## 🔄 Maintenance

### Windows Updates
Configured automatically in Ansible playbook.

### Software Updates
```bash
# Update Chocolatey packages
choco upgrade all -y
```

### Fortify Updates
```bash
# Replace installer in C:\temp and re-run Ansible role
```

## 📞 Support

For issues:
1. Check logs: `terraform.log`, `ansible.log`
2. Review troubleshooting guides
3. Check Azure Portal for resource errors
4. Verify credentials and permissions

## 📝 License

Internal use only.

## 🎓 Learning Resources

- [Terraform Azure Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Ansible Windows Guide](https://docs.ansible.com/ansible/latest/user_guide/windows.html)
- [Azure VM Documentation](https://docs.microsoft.com/azure/virtual-machines/)
- [Fortify Documentation](https://www.microfocus.com/en-us/products/static-code-analysis-sast/overview)

## 🔄 Workflow

```
┌──────────────────────┐
│ 1. Configure Terraform│
│    (variables.tfvars) │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ 2. Deploy with       │
│    Terraform         │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ 3. Update Ansible    │
│    Inventory (IP)    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ 4. Run Ansible       │
│    Playbooks         │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ 5. Connect via RDP   │
│    Test Installation │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ 6. Upload Files &    │
│    Run Scans         │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ 7. Build Mobile Apps │
│    & Test            │
└──────────────────────┘
```

## 📋 Checklist

- [ ] Azure login configured
- [ ] Terraform initialized
- [ ] Variables configured (passwords, IPs)
- [ ] Infrastructure deployed
- [ ] Ansible inventory updated
- [ ] Ansible connectivity verified
- [ ] Configuration applied
- [ ] Installation verified
- [ ] RDP connection tested
- [ ] Fortify license uploaded
- [ ] Source code added
- [ ] Scans completed
- [ ] Mobile apps built

## 🔗 Quick Links

- [Terraform Docs](terraform/README.md)
- [Ansible Docs](ansible/README.md)
- [Azure Portal](https://portal.azure.com)
- [hawapay Subscription](https://portal.azure.com/#@hawapay.onmicrosoft.com/)

---

**Last Updated**: 2024
**Status**: Production Ready
**Maintained By**: DevOps Team
