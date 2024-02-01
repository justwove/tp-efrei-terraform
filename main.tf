terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "GR-Latif" {
    name    = "GR-Latif"
    location = "East US"
  
}

resource "azurerm_application_gateway" "myAppGatewayLatif" {
  name                = "myAppGatewayLatif"
  resource_group_name = azurerm_resource_group.GR-Latif.name
  location            = azurerm_resource_group.GR-Latif.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 10 
  }

  waf_configuration{
    enabled             = true
    firewall_mode       = "Detection"
    rule_set_type       = "OWASP"
    rule_set_version    = 3.2
  }

  gateway_ip_configuration {
    name      = "LatifIPconfig"
    subnet_id = azurerm_subnet.MyAGSubnet.id
  }
  
  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.myAGPublicLatif.id
  }

    
  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  backend_address_pool {
    name = local.backend_address_pool_name
    
    ip_addresses = [
      azurerm_network_interface.Interface_VM1-Latif.private_ip_address,
      azurerm_network_interface.Interface_VM2-Latif.private_ip_address
      ]
  }

  backend_http_settings {
    name                  = local.http_setting_name
    protocol              = "Http"
    port                  = 80
    cookie_based_affinity = "Disabled"
    request_timeout       = 20
  }
}



resource "azurerm_public_ip" "myAGPublicLatif" {
  name                = "myAGPublicLatif"
  resource_group_name = azurerm_resource_group.GR-Latif.name
  location            = azurerm_resource_group.GR-Latif.location
  allocation_method   = "Static"
  sku = "Standard"
}



resource "azurerm_virtual_network" "MyVnet-Latif" {
    name                = "MyVnet-Latif"
    address_space       = ["10.21.0.0/16"]
    location            = azurerm_resource_group.GR-Latif.location
    resource_group_name = azurerm_resource_group.GR-Latif.name
  
}

resource "azurerm_subnet" "MyAGSubnet" {
    name                    = "MyAGSubnet"
    virtual_network_name    = azurerm_virtual_network.MyVnet-Latif.name
    resource_group_name     = azurerm_resource_group.GR-Latif.name
    address_prefixes        = [ "10.21.0.0/24" ]
}

resource "azurerm_subnet" "myBackendSubnet" {
    name                    = "myBackendSubnet"
    virtual_network_name    = azurerm_virtual_network.MyVnet-Latif.name
    resource_group_name     = azurerm_resource_group.GR-Latif.name
    address_prefixes        = [ "10.21.1.0/24" ]
}

resource "azurerm_application_gateway_backend_address_pool" "myBackendPool" {
  name                = "myBackendPool"
  resource_group_name = azurerm_resource_group.GR-Latif.name
  application_gateway_name = azurerm_application_gateway.myAppGatewayLati.name
}

#### Seb
resource "azurerm_network_interface" "Interface_VM1-Latif" {
    name = "Interface_VM1-Latif"
    resource_group_name = azurerm_resource_group.GR-Latif.name
    location = azurerm_resource_group.GR-Latif.location
    ip_configuration {
      name = "Interface_VM1-Latif-conf"
      subnet_id = azurerm_subnet.myBackendSubnet.id
      private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_network_interface" "Interface_VM2-Latif" {
    name = "Interface_VM2-Latif"
    resource_group_name = azurerm_resource_group.GR-Latif.name
    location = azurerm_resource_group.GR-Latif.location
    ip_configuration {
      name = "Interface_VM2-Latif-conf"
      subnet_id = azurerm_subnet.myBackendSubnet.id
      private_ip_address_allocation = "Dynamic"
    }
}


resource "azurerm_linux_virtual_machine" "VM1-Latif" {
    name =  "VM1-Latif"
    resource_group_name = azurerm_resource_group.GR-Latif.name
    location = azurerm_resource_group.GR-Latif.location
    size = "Standard_B1s"
    disable_password_authentication = false  
    admin_username = "azureuser"
    admin_password = "jaimelasecurite"
    os_disk {
      caching = "ReadWrite"
      storage_account_type = "Standard_LRS"
    }
    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
    }
    network_interface_ids = [azurerm_network_interface.Interface_VM1-Latif.id]
  
}

resource "azurerm_linux_virtual_machine" "VM2-Latif" {
    name =  "VM2-Latif"
    resource_group_name = azurerm_resource_group.GR-Latif.name
    location = azurerm_resource_group.GR-Latif.location
    size = "Standard_B1s"
    disable_password_authentication = false  
    admin_username = "azureuser"
    admin_password = "jaimelasecurite"
    os_disk {
      caching = "ReadWrite"
      storage_account_type = "Standard_LRS"
    }
    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
    }
    network_interface_ids = [azurerm_network_interface.Interface_VM2-Latif.id]
  
}


locals {
  backend_address_pool_name      = "${azurerm_virtual_network.MyVnet-Latif.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.MyVnet-Latif.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.MyVnet-Latif.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.MyVnet-Latif.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.MyVnet-Latif.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.MyVnet-Latif.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.MyVnet-Latif.name}-rdrcfg"
}

resource "azurerm_virtual_machine_extension" "nginx_script1" {
  name                = "nginx_script1"
  virtual_machine_id  = azurerm_linux_virtual_machine.VM1-Latif.id
  publisher           = "Microsoft.Azure.Extensions"
  type                = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
      "fileUris": ["https://raw.githubusercontent.com/Azure/azure-docs-powershell-samples/master/application-gateway/iis/install_nginx.sh"],
      "commandToExecute": "./install_nginx.sh"
    }
SETTINGS
}

resource "azurerm_virtual_machine_extension" "nginx_script2" {
  name                = "nginx_script2"
  virtual_machine_id  = azurerm_linux_virtual_machine.VM2-Ellie-TF.id
  publisher           = "Microsoft.Azure.Extensions"
  type                = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
      "fileUris": ["https://raw.githubusercontent.com/Azure/azure-docs-powershell-samples/master/application-gateway/iis/install_nginx.sh"],
      "commandToExecute": "./install_nginx.sh"
    }
SETTINGS
}