# Azure Service Fabric Architecture

This is a Powershell Infrastruture as Code (iac) automation solution for a Secure Service Fabric Architecture.

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

1. KeyVault - Local Admininstrator Information, Service Fabric Certificates
1. Azure Storage Account - Diagnostic Storage
1. Azure Storage Account - Log Storage
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

#### Install Base Resources
Environment dev (.env_dev.ps1) or prd (.env_prd.ps1)

```powershell
# Install the Base Resources
./install.ps1 -Base $true -Environment 'dev'
```

#### Install Routing Resources
```powershell
# Install the Routing Resources
./install.ps1 -Routing 'PublicLB' -Environment 'dev'
```

#### Install Cluster Resources

```powershell
# Install the Cluster Resources
./install.ps1 -Cluster $true -Environment 'dev'
```

#### Enable Active Directory RBAC Integration

```powershell
# Install the Cluster Resources
./install.ps1 -RBAC $true -Environment 'dev'

# Add the Response into the .env file.
$Env:CLUSTER_APP = "<your_web_application>"
$Env:CLIENT_APP = "<your_native_client_app>"

```

#### Install Package Application

```powershell
# Deploy the Application Package
./deploy.ps1 -Environment dev -Name Voting
./deploy.ps1 -Environment dev -Name SimpleApp.SfProd
```
