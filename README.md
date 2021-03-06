# Azure Service Fabric Architecture

This is a Powershell Infrastruture as Code (iac) automation solution for a Secure Service Fabric Architecture.

[![Build Status](https://dascholl.visualstudio.com/Demos/_apis/build/status/azure-fabric-arch/danielscholl.azure-fabric-arch-quickstart?branchName=master)](https://dascholl.visualstudio.com/Demos/_build/latest?definitionId=21?branchName=master) _Application Quickstart_

[![Build Status](https://dascholl.visualstudio.com/Demos/_apis/build/status/azure-fabric-arch/danielscholl.azure-fabric-arch-quickstart?branchName=master)](https://dascholl.visualstudio.com/Demos/_build/latest?definitionId=21?branchName=master) _Application SimpleApp_

[![Build Status](https://dascholl.visualstudio.com/Demos/_apis/build/status/azure-fabric-arch/danielscholl.azure-fabric-arch-iac?branchName=master)](https://dascholl.visualstudio.com/Demos/_build/latest?definitionId=20?branchName=master) _Infrastucture as Code_

__Requirements:__

1. [Windows Powershell](https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell?view=powershell-5.1)

```powershell
  $PSVersionTable.PSVersion

  # Result
  Major  Minor  Build  Revision
  -----  -----  -----  --------
  5      1      17134  407
```

2. [Azure PowerShell Modules](https://www.powershellgallery.com/packages/Azure/5.1.1)

```powershell
  Get-Module Azure -list | Select-Object Name,Version

  # Result
  Name  Version
  ----  -------
  Azure 5.1.2
```

3. [AzureRM Powershell Modules](https://www.powershellgallery.com/packages/AzureRM/5.1.1)

```powershell
  Get-Module AzureRM.* -list | Select-Object Name,Version

  # Result
  Name                                  Version
  ----                                  -------
  AzureRM.Compute                       5.5.0
  AzureRM.KeyVault                      5.1.1
  AzureRM.Network                       6.5.0
  AzureRM.Profile                       5.4.0
  AzureRM.Resources                     6.4.0
  AzureRM.Storage                       5.0.2
```

4. [Open SSL](https://slproweb.com/products/Win32OpenSSL.html)

__Installation:__

Install Required PowerShell Modules if needed

```powershell
Install-Module AzureRM
Import-Module AzureRM
```

## Azure Network Architecture

The Network scheme is an ARM Network scheme with multiple subnets.

__Network Resource Requirements:__

- A Unique /24 Address Space  ie: 10.0.0.0/24
- Azure Region Location (EastUS)
- Subnet 1 DefaultSubnet 10.0.0.0/26
- Subnet 2 GatewaySubnet 10.0.0.224/28

## Azure Service Fabric Architecture

The architecture depends upon the following items:

1. KeyVault - Fabric Configuration Information, Service Fabric Certificates
1. Azure Storage Account - Diagnostic & Logging Storage
1. Azure Network - 2 Subnets (Small)
1. Azure Load Balancer - Public Facing Load Balancer with NAT
1. Azure VM Scale Set with Azure Service Fabric Cluster


### Scale Set Requirements

| Size           | vCPU | Memory (GiB) | Network Bandwidth MBps | Instances |
| -------------- | ---- | ------------ | ---------------------- | --------- |
| Standard_D2_v2 | 2    | 7            | 1500                   | 1         |

| OS Disk     | Disk Type    | Disk Throughput (IOPS/MBps) |
| ----------- | ------------ | --------------------------- |
| Managed SSD | Standard_LRS |                             |

## Installation Procedure

>NOTE: ALWAYS USE A NEW POWERSHELL SESSION!!!

### Create Environment File

Environment files are used as project environments  ie:  dev, test, production and provide a convenient place to place override parameter settings.  The majority of these settings are loaded into a Key Vault to be used for the CI/CD Pipelines.

Create an environment setting file in the root directory ie: `.env_dev.ps1`

Default Environment Settings

| Parameter            | Default                              | Description                              |
| -------------------- | ------------------------------------ | ---------------------------------------- |
| _AZURE_TENANT_       | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx | Azure Tenant Id                          |
| _AZURE_SUBSCRIPTION_ | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx | Azure Subscription Id                    |
| _AZURE_PRINCIPAL_    | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx | Azure Principal App Id                   |
| _AZURE_LOCATION_     | EastUS2                              | Azure Region for Resources to be located |
| _AZURE_ANALYTICS_    | xxxxxxx                              | Azure Log Analytics Name                 |
| _AZURE_RANDOM_       | 123                                  | 3 Digit Random Identifier                |
| _AZURE_GROUP_        | fabric                               | Azure Resource Group Name                |
| _AZURE_USERNAME_     | localAdmin                           | Default Local Admin UserName             |
| _AZURE_PASSWORD_     | localPassword                        | Default Local Admin Password             |
| _FABRIC_TIER_        | bronze                               | Service Fabric Durability Level          |
| _FABRIC_NODE_COUNT_  | 1                                    | Service Fabric NodeSet Instance Count    |

### Create Resources
Resources are broken up into sections only for the purpose of not having an excessively long running task.


#### Login to Azure and set the desired subscription

```powershell
Login-AzureRmAccount
Set-AzureRmContext -Subscription "<subscription_name>"
```


#### Prepare the environment
This will create the resource group and the keyvault, then load all the configurations needed into the Key Vault.  Environments align themselves in the naming conventions used.

dev --> .env_dev.ps1
test --> .env_test.ps1
prd --> .env_prd.ps1

```powershell
# Prepare the Base Resources
./install.ps1 -Prepare $true -Environment 'dev'
```


#### Enable Active Directory RBAC Integration
RBAC is an optional security feature that will allow a user to login via Azure AD credentials.  To perform this the user running the script "must" have administration rights within Azure AD, as this will execute the aadtool scripts.

This only needs to be performed 1 time to enable the AD Integration Applications that can be used.

```powershell
# Install the Cluster Resources
./install.ps1 -RBAC $true -Environment 'dev'

# Add the Application Information into the .env file.
$Env:CLUSTER_APP = "<your_web_application>"
$Env:CLIENT_APP = "<your_native_client_app>"
```
> Note: After creation you have to add the user to the Users & Groups fpr the Enterprise Cluster Application and give them the authorized role.


#### Install the supporting infrastructure and cluster resources
This will setup the storage, network and load balancer resources.

```powershell
# Install the Routing Resources
./install.ps1 -Infrastructure $true -Cluster $true  -Environment 'dev'
```


#### Install the Application Package

```powershell
# Deploy the Ingress Controller  (UI on Port 8080)
./deploy.ps1 -Environment 'dev' -Name Traefik

# Deploy the Desired Application Package  (UI on Port 80)
./deploy.ps1 -Environment dev -Name SimpleApp.SfProd
./deploy.ps1 -Environment dev -Name Voting
```
