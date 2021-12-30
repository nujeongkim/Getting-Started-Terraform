terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.31.1"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "like-and-subscribe"
  location = "southcentralus"
  tags = {
    environment = "dev"
    source      = "Terraform"
    owner       = "Jeong"
  }
}

resource "azurerm_virtual_network" "myterraformnetwork" {
  name                = "myVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = "Example VM"
  }
}

resource "azurerm_subnet" "myterraformsubnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "myterraformpublicip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  tags = {
    environment = "Example VM"
  }
}

resource "azurerm_network_security_group" "myterraformnsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = "Example VM"
  }
}

resource "azurerm_network_security_rule" "myterraformssh" {
  name                        = "ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.myterraformnsg.name
}

resource "azurerm_network_security_rule" "myterraformhttp" {
  name                        = "http"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.myterraformnsg.name
}

resource "azurerm_network_security_rule" "myterraformsql" {
  name                        = "http"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3306"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.myterraformnsg.name
}

resource "azurerm_network_interface" "myterraformnic" {
  name                = "myNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "muNicConfiguration"
    subnet_id                     = azurerm_subnet.myterraformsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
  }
  tags = {
    environment = "Example VM"
  }
}

resource "azurerm_network_interface_security_group_association" "myterraformnicassoc" {
  network_interface_id      = azurerm_network_interface.myterraformnic.id
  network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

resource "random_id" "myterraformid" {
  keepers = {
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8

}

resource "azurerm_storage_account" "myterraformaccount" {
  name                     = "diag${random_id.myterraformid.hex}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
  tags = {
    environment = "Example VM"
  }

}

resource "azurerm_linux_virtual_machine" "myterraformvm" {
  name                            = "myVM"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  network_interface_ids           = [azurerm_network_interface.myterraformnic.id]
  size                            = "Standard_A1_v2"
  disable_password_authentication = false

  os_disk {
    name                 = "osdisk1"
    disk_size_gb         = "32"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "nilespartnersinc1617691698386"
    offer     = "wordpress-5-7_09-04-2021"
    sku       = "wordpress"
    version   = "latest"
  }

  plan {
    name      = "wordpress"
    publisher = "nilespartnersinc1617691698386"
    product   = "wordpress-5-7_09-04-2021"
  }

  computer_name  = "myvm"
  admin_username = "vmadmin"
  admin_password = "Password12345!"

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.myterraformaccount.primary_blob_endpoint
  }

  tags = {
    environment = "Example VM"
  }
}

