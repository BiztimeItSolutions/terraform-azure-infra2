.PHONY: help init plan apply destroy verify clean setup test

# Default target
.DEFAULT_GOAL := help

# Variables
TERRAFORM_DIR := terraform
ANSIBLE_DIR := ansible
PYTHON_VERSION := 3.8

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)hawapay Infrastructure Management$(NC)"
	@echo "$(BLUE)===============================$(NC)"
	@echo ""
	@echo "$(GREEN)Available Commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Quick Start:$(NC)"
	@echo "  1. make setup       - Setup development environment"
	@echo "  2. make init        - Initialize Terraform"
	@echo "  3. make plan        - Plan infrastructure changes"
	@echo "  4. make apply       - Deploy infrastructure"
	@echo "  5. make ansible     - Configure with Ansible"
	@echo "  6. make verify      - Verify installation"
	@echo ""

setup: ## Setup development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	pip3 install --upgrade pip
	pip3 install -r requirements.txt
	cd $(ANSIBLE_DIR) && ansible-galaxy install -r requirements.yml
	@echo "$(GREEN)✓ Setup complete!$(NC)"

init: ## Initialize Terraform
	@echo "$(BLUE)Initializing Terraform...$(NC)"
	cd $(TERRAFORM_DIR) && terraform init
	@echo "$(GREEN)✓ Terraform initialized!$(NC)"

plan: ## Plan infrastructure changes
	@echo "$(BLUE)Planning infrastructure changes...$(NC)"
	cd $(TERRAFORM_DIR) && terraform plan -out=tfplan
	@echo "$(GREEN)✓ Plan saved to tfplan$(NC)"

apply: ## Deploy infrastructure
	@echo "$(BLUE)Applying Terraform configuration...$(NC)"
	cd $(TERRAFORM_DIR) && terraform apply tfplan
	@echo "$(GREEN)✓ Infrastructure deployed!$(NC)"

destroy: ## Destroy infrastructure
	@echo "$(RED)WARNING: This will destroy all resources!$(NC)"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ] || exit 1
	cd $(TERRAFORM_DIR) && terraform destroy
	@echo "$(GREEN)✓ Infrastructure destroyed!$(NC)"

output: ## Show Terraform outputs
	@echo "$(BLUE)Terraform Outputs:$(NC)"
	cd $(TERRAFORM_DIR) && terraform output
	@echo ""

test-terraform: ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform...$(NC)"
	cd $(TERRAFORM_DIR) && terraform validate
	cd $(TERRAFORM_DIR) && terraform fmt -check
	@echo "$(GREEN)✓ Terraform validation passed!$(NC)"

ansible-check: ## Check Ansible connectivity
	@echo "$(BLUE)Testing Ansible connectivity...$(NC)"
	ansible all -i $(ANSIBLE_DIR)/inventory/hosts.ini -m win_ping
	@echo "$(GREEN)✓ Ansible connectivity verified!$(NC)"

ansible: ## Run main Ansible playbook
	@echo "$(BLUE)Running Ansible configuration...$(NC)"
	ansible-playbook -i $(ANSIBLE_DIR)/inventory/hosts.ini $(ANSIBLE_DIR)/playbooks/main.yml
	@echo "$(GREEN)✓ Ansible configuration complete!$(NC)"

ansible-verbose: ## Run Ansible with verbose output
	@echo "$(BLUE)Running Ansible configuration (verbose)...$(NC)"
	ansible-playbook -i $(ANSIBLE_DIR)/inventory/hosts.ini $(ANSIBLE_DIR)/playbooks/main.yml -vvv
	@echo "$(GREEN)✓ Ansible configuration complete!$(NC)"

ansible-check-mode: ## Run Ansible in check mode (dry run)
	@echo "$(BLUE)Running Ansible in check mode...$(NC)"
	ansible-playbook -i $(ANSIBLE_DIR)/inventory/hosts.ini $(ANSIBLE_DIR)/playbooks/main.yml --check
	@echo "$(GREEN)✓ Ansible check mode complete!$(NC)"

verify: ## Verify installation
	@echo "$(BLUE)Verifying installation...$(NC)"
	ansible-playbook -i $(ANSIBLE_DIR)/inventory/hosts.ini $(ANSIBLE_DIR)/playbooks/verify.yml
	@echo "$(GREEN)✓ Verification complete!$(NC)"

reinstall-fortify: ## Reinstall Fortify Scan
	@echo "$(BLUE)Reinstalling Fortify...$(NC)"
	ansible-playbook -i $(ANSIBLE_DIR)/inventory/hosts.ini $(ANSIBLE_DIR)/playbooks/main.yml --tags fortify
	@echo "$(GREEN)✓ Fortify reinstalled!$(NC)"

reinstall-sublime: ## Reinstall Sublime Text
	@echo "$(BLUE)Reinstalling Sublime Text...$(NC)"
	ansible-playbook -i $(ANSIBLE_DIR)/inventory/hosts.ini $(ANSIBLE_DIR)/playbooks/main.yml --tags sublime
	@echo "$(GREEN)✓ Sublime Text reinstalled!$(NC)"

deploy-sourcecode: ## Deploy source code
	@echo "$(BLUE)Deploying source code...$(NC)"
	ansible-playbook -i $(ANSIBLE_DIR)/inventory/hosts.ini $(ANSIBLE_DIR)/playbooks/main.yml --tags sourcecode
	@echo "$(GREEN)✓ Source code deployed!$(NC)"

configure-rdp: ## Configure RDP
	@echo "$(BLUE)Configuring RDP...$(NC)"
	ansible-playbook -i $(ANSIBLE_DIR)/inventory/hosts.ini $(ANSIBLE_DIR)/playbooks/main.yml --tags rdp
	@echo "$(GREEN)✓ RDP configured!$(NC)"

docs: ## Show documentation
	@echo "$(BLUE)Documentation:$(NC)"
	@echo "  - Main README: ./README.md"
	@echo "  - Quick Start: ./docs/GETTING_STARTED.md"
	@echo "  - Deployment: ./docs/DEPLOYMENT.md"
	@echo "  - Troubleshooting: ./docs/TROUBLESHOOTING.md"
	@echo "  - Terraform: ./terraform/README.md"
	@echo "  - Ansible: ./ansible/README.md"
	@echo ""
	@echo "$(GREEN)Open a file:$(NC)"
	@echo "  make docs-quickstart   - Open Quick Start"
	@echo "  make docs-deployment   - Open Deployment Guide"
	@echo "  make docs-terraform    - Open Terraform Docs"
	@echo "  make docs-ansible      - Open Ansible Docs"

docs-quickstart: ## Open Quick Start guide
	@which xdg-open > /dev/null && xdg-open docs/GETTING_STARTED.md || open docs/GETTING_STARTED.md || cat docs/GETTING_STARTED.md

docs-deployment: ## Open Deployment guide
	@which xdg-open > /dev/null && xdg-open docs/DEPLOYMENT.md || open docs/DEPLOYMENT.md || cat docs/DEPLOYMENT.md

docs-terraform: ## Open Terraform documentation
	@which xdg-open > /dev/null && xdg-open terraform/README.md || open terraform/README.md || cat terraform/README.md

docs-ansible: ## Open Ansible documentation
	@which xdg-open > /dev/null && xdg-open ansible/README.md || open ansible/README.md || cat ansible/README.md

get-ip: ## Get VM public IP
	@echo "$(BLUE)VM Public IP:$(NC)"
	@cd $(TERRAFORM_DIR) && terraform output -raw vm_public_ip 2>/dev/null || echo "Run 'make apply' first"

get-rdp: ## Get RDP connection string
	@echo "$(BLUE)RDP Connection String:$(NC)"
	@cd $(TERRAFORM_DIR) && terraform output -raw rdp_connection_string 2>/dev/null || echo "Run 'make apply' first"

get-inventory: ## Get Ansible inventory entry
	@echo "$(BLUE)Ansible Inventory Entry:$(NC)"
	@cd $(TERRAFORM_DIR) && terraform output -raw ansible_inventory_entry 2>/dev/null || echo "Run 'make apply' first"

clean: ## Clean up temporary files
	@echo "$(BLUE)Cleaning up...$(NC)"
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	rm -f terraform/tfplan
	rm -f ansible.log
	rm -f terraform.log
	@echo "$(GREEN)✓ Cleanup complete!$(NC)"

format: ## Format Terraform code
	@echo "$(BLUE)Formatting Terraform code...$(NC)"
	cd $(TERRAFORM_DIR) && terraform fmt -recursive
	@echo "$(GREEN)✓ Formatting complete!$(NC)"

logs: ## Show Ansible logs
	@echo "$(BLUE)Ansible Logs:$(NC)"
	@tail -50 ansible.log 2>/dev/null || echo "No logs yet"

state: ## Show Terraform state
	@echo "$(BLUE)Terraform State:$(NC)"
	cd $(TERRAFORM_DIR) && terraform state list
	@echo ""

state-show: ## Show VM resource in state
	@echo "$(BLUE)VM Resource State:$(NC)"
	cd $(TERRAFORM_DIR) && terraform state show azurerm_windows_virtual_machine.vm

azure-login: ## Login to Azure
	@echo "$(BLUE)Logging in to Azure...$(NC)"
	az login
	@echo "$(GREEN)✓ Logged in!$(NC)"

azure-set-subscription: ## Set Azure subscription
	@echo "$(BLUE)Setting Azure subscription...$(NC)"
	az account set --subscription "11fe1111-11e-1111-1111-11111ea011111"
	@echo "$(GREEN)✓ Subscription set!$(NC)"

azure-show-subscription: ## Show current Azure subscription
	@echo "$(BLUE)Current Subscription:$(NC)"
	az account show --output table

azure-show-vm: ## Show VM details
	@echo "$(BLUE)VM Details:$(NC)"
	az vm show -d --name vm-hawapay-scan-test --resource-group rg-hawapay-test --output table

full-deploy: init plan apply ansible verify ## Full deployment (init -> apply -> ansible -> verify)
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)✓ FULL DEPLOYMENT COMPLETE!$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@make get-rdp
	@echo ""

redeploy: destroy apply ansible verify ## Redeploy everything
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)✓ REDEPLOYMENT COMPLETE!$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@make get-rdp
	@echo ""

.PHONY: version
version: ## Show versions
	@echo "$(BLUE)Versions:$(NC)"
	@terraform -version 2>/dev/null || echo "Terraform: Not installed"
	@ansible --version 2>/dev/null || echo "Ansible: Not installed"
	@python3 --version 2>/dev/null || echo "Python: Not installed"
	@az --version 2>/dev/null | head -1 || echo "Azure CLI: Not installed"
