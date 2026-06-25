resource "azurerm_network_interface" "vm_nic" {
  name                = "nutriai-vm-nic-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.vm_subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

locals {
  install_script = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release wget

    # Install Azure CLI
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash

    # Install kubectl
    mkdir -p /etc/apt/keyrings
    for i in {1..10}; do
      if curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key -o /tmp/Release.key; then
        gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg /tmp/Release.key
        rm -f /tmp/Release.key
        break
      fi
      echo "Failed to download Kubernetes GPG key, retrying in 5 seconds..."
      sleep 5
    done
    chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
    apt-get update -y
    apt-get install -y kubectl

    # Install Terraform
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
    apt-get update -y
    apt-get install -y terraform
  EOT
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "nutriai-vm-${var.environment}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.vm_nic.id]
  custom_data                     = base64encode(local.install_script)

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}
