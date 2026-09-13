# Quick Start Guide

Get up and running with hawapay infrastructure in 5 steps.

## Prerequisites
- Terraform >= 1.0
- Ansible >= 2.9
- Azure CLI installed and authenticated
- Python 3.8+

## Step 1: Configure (5 minutes)

```bash
cd terraform/

# Update variables
nano terraform.tfvars
```

**Essential changes**:
```hcl
admin_password = "YourSecurePassword123!"  # ✓ CHANGE THIS
rdp_source_ip = "YOUR.IP.ADDRESS/32"      # ✓ RESTRICT THIS
```

## Step 2: Deploy Infrastructure (10 minutes)

```bash
# Initialize
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Capture output
terraform output -raw vm_public_ip > public_ip.txt
```

## Step 3: Configure Ansible (2 minutes)

```bash
cd ../ansible/

# Update inventory with public IP
PUBLIC_IP=$(cat ../public_ip.txt)
sed -i "s/<PUBLIC_IP>/$PUBLIC_IP/g" inventory/hosts.ini

# Verify connectivity
ansible all -i inventory/hosts.ini -m win_ping
```

## Step 4: Run Ansible (20 minutes)

```bash
# Configure VM
ansible-playbook -i inventory/hosts.ini playbooks/main.yml

# Wait for completion...
```

## Step 5: Connect and Verify (5 minutes)

```bash
# Get connection details
PUBLIC_IP=$(terraform -chdir=../terraform output -raw vm_public_ip)

# Connect via RDP
rdesktop -u azureuser -p 'YourPassword' $PUBLIC_IP:3389

# Or Windows:
# mstsc.exe → $PUBLIC_IP:3389
```

## Estimated Total Time: 40-50 minutes

### Detailed breakdown:
- Prerequisites: 5 min
- Terraform init: 2 min
- Terraform plan: 2 min
- Terraform apply: 5-10 min
- VM initialization: 5 min
- Ansible configuration: 2 min
- Ansible playbook: 15-30 min
- Verification: 5 min

## What's Installed

✓ Fortify Scan (C:\Fortify)
✓ Sublime Text (C:\Program Files\Sublime Text)
✓ Git, 7-Zip, Chocolatey
✓ Source code directory (Desktop)
✓ RDP optimized and ready

## Next Steps

1. **Upload Fortify License**
   - Copy license.dat to C:\Fortify\

2. **Add Source Code**
   - Copy to C:\Users\azureuser\Desktop\SourceCode

3. **Run Fortify Scan**
   ```powershell
   C:\Fortify\scan-source-code.ps1 -BuildName "MyProject"
   ```

4. **Build Mobile Apps**
   - Android: 2 builds (with/without SSL pinning)
   - iOS: 2 builds (with/without root detection)

## Common Commands

```bash
# View Terraform outputs
terraform -chdir=terraform output

# Re-run specific Ansible role
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/main.yml --tags fortify

# Verify installation
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/verify.yml

# Destroy everything
terraform -chdir=terraform destroy
```

## Troubleshooting

### Can't connect with Ansible?
```bash
# Wait 5 minutes and retry
sleep 300
ansible all -i inventory/hosts.ini -m win_ping
```

### RDP connection fails?
```bash
# Wait 3 minutes for services to start
# Check public IP is correct
terraform -chdir=terraform output vm_public_ip
```

### Need to redo Ansible?
```bash
# Just re-run it (idempotent)
ansible-playbook -i inventory/hosts.ini playbooks/main.yml
```

## For Detailed Instructions

- **Terraform**: See [terraform/README.md](terraform/README.md)
- **Ansible**: See [ansible/README.md](ansible/README.md)
- **Full Deployment**: See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)
- **Troubleshooting**: See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

**Ready to start?** Begin with Step 1!
