provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "dev-aks-jenkins-rg"
  location = "EastUS"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "dev-aks-jenkins-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "snet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "azurerm_network_interface" "nic" {
  name                = "dev-aks-jenkins-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = var.public_ip_id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "dev-aks-jenkins-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "devuser"
  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "devuser"
    public_key = tls_private_key.ssh.public_key_openssh
  }

custom_data = base64encode(<<EOF
#!/bin/bash
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo docker pull jenkins/jenkins
sudo docker run -d -v /var/run/docker.sock:/var/run/docker.sock -p 8080:8080 -p 50000:50000 jenkins/jenkins
EOF
  )
}
resource "azurerm_kubernetes_cluster" "example" {
  name                = "dev-aks-jenkins-aks"
  location            = "eastus"
  resource_group_name = "dev-aks-jenkins-rg"
  dns_prefix          = "jenkinsaks1"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Dev"
  }
}

output "client_certificate" {
  description = "The Kubernetes client certificate"
  sensitive = true
  value       = azurerm_kubernetes_cluster.example.kube_config.0.client_certificate
}

resource "azurerm_container_registry" "example" {
  name                     = "devaksjenkinsacr"
  resource_group_name      = "dev-aks-jenkins-rg"
  location                 = "eastus"
  sku                      = "Basic"
  admin_enabled            = true
}

output "kube_config" {
  description = "Kubernetes configuration file"
  sensitive = true
  value       = azurerm_kubernetes_cluster.example.kube_config_raw
}

output "acr_login_server" {
  description = "The URL that can be used to log into the container registry."
  value       = azurerm_container_registry.example.login_server
}

output acr_credentials {
  description = "The admin username and password for the container registry."
  sensitive = true
  value = {
    username = azurerm_container_registry.example.admin_username
    password = azurerm_container_registry.example.admin_password
  }
}

output "private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}