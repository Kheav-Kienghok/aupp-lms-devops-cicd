.PHONY: help setup

MAKEFILES_DIR := makefiles

help:
	@echo ""
	@echo "DevOp-Final Main Makefile"
	@echo "========================================"
	@echo ""
	@echo "Run everything in ONE command:"
	@echo "  make setup   - Install Terraform + Ansible, then run terraform init/apply"
	@echo ""

# ONE command setup
setup:
	@echo ""
	@echo "========================================"
	@echo " Installing Terraform + Ansible, then provisioning infra..."
	@echo "========================================"
	@echo ""

	@make -f $(MAKEFILES_DIR)/Makefile.terraform install-terraform
	@make -f $(MAKEFILES_DIR)/Makefile.ansible install-ansible
	@make -f $(MAKEFILES_DIR)/Makefile.setup terraform-setup

	@echo ""
	@echo "Setup completed successfully"
	@echo ""