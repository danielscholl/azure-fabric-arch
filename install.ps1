<#
.SYNOPSIS
  Install the Full Infrastructure As Code Solution
.DESCRIPTION
  This Script will install all the infrastructure needed for the solution.

  1. Resource Group


.EXAMPLE
  .\install.ps1
  Version History
  v1.0   - Initial Release
#>
#Requires -Version 5.1
#Requires -Module @{ModuleName='AzureRM.Resources'; ModuleVersion='5.0'}

param(
  [boolean] $Prepare = $false,
  [boolean] $Infrastructure = $false,
  [boolean] $RBAC = $false,
  [boolean] $Cluster = $false,

  [Parameter(Mandatory = $true)] [string] $Environment,
  [string] $ResourceGroupName = "$env:AZURE_RANDOM-$env:AZURE_GROUP",
  [string] $Location = $env:AZURE_LOCATION,
  [string] $Prefix = $env:AZURE_GROUP,
  [string] $Random = $env:AZURE_RANDOM
)

# Clear any existing environment settings.
$Env:AZURE_TENANT = [string]::Empty
$Env:AZURE_SUBSCRIPTION = [string]::Empty
$Env:AZURE_PRINCIPAL = [string]::Empty
$Env:AZURE_LOCATION = [string]::Empty
$Env:AZURE_GROUP = [string]::Empty
$Env:AZURE_RANDOM = [string]::Empty
$Env:AZURE_USERNAME = [string]::Empty
$Env:AZURE_PASSWORD = [string]::Empty
$Env:AZURE_ANALYTICS = [string]::Empty
$Env:AZURE_ANALYTICS_KEY = [string]::Empty
$Env:FABRIC_TIER = [string]::Empty
$Env:FABRIC_NODE_COUNT = 0
$Env:CLUSTER_APP = [string]::Empty
$Env:CLIENT_APP = [string]::Empty

# Load Project Environment Settings and Functions
if (Test-Path "$PSScriptRoot\.env_$Environment.ps1") { . "$PSScriptRoot\.env_$Environment.ps1" }
if (Test-Path "$PSScriptRoot\infrastructure\functions.ps1") { . "$PSScriptRoot\infrastructure\functions.ps1" }

# Display Project Environment Settings
Get-ChildItem Env:AZURE*
Get-ChildItem Env:FABRIC*

if ($Prepare -eq $true) {
  Write-Host "Preparing for Install here we go...." -ForegroundColor "cyan"
  & ./infrastructure/iac-keyvault/install.ps1 -Prefix "sf$Random" -Environment $Environment

  Write-Host "---------------------------------------------" -ForegroundColor "blue"
  Write-Host "Preparation has been completed!!!!!" -ForegroundColor "red"
  Write-Host "---------------------------------------------" -ForegroundColor "blue"
}

if ($Infrastructure -eq $true) {
  Write-Host "Install Routing Resources here we go...." -ForegroundColor "cyan"
  & ./infrastructure/iac-storage/install.ps1 -Prefix "sf$Random"
  & ./infrastructure/iac-network/install.ps1 -Prefix "sf$Random"
  & ./infrastructure/iac-publicLB/install.ps1 -Prefix "sf$Random"

  Write-Host "---------------------------------------------" -ForegroundColor "blue"
  Write-Host "Routing Components have been installed!!!!!" -ForegroundColor "red"
  Write-Host "---------------------------------------------" -ForegroundColor "blue"
}

if ($Cluster -eq $true) {
  Write-Host "Install Cluster Resources here we go...." -ForegroundColor "cyan"
  & ./infrastructure/iac-serviceFabric/install.ps1 -Prefix "sf$Random"

  Write-Host "---------------------------------------------" -ForegroundColor "blue"
  Write-Host "Cluster Components have been installed!!!!!" -ForegroundColor "red"
  Write-Host "---------------------------------------------" -ForegroundColor "blue"

  $env:Endpoint = "sf$Random.eastus2.cloudapp.azure.com:19000"
  Write-Color -Text "Endpoint = ", $env:Endpoint -Color green, red
}

if ($RBAC -eq $true) {
  $tenantId = (Get-AzureRmContext).Tenant.Id
  $replyUrl = "https://sf$Random.$Location.cloudapp.azure.com:19080/Explorer/index.html"
  $clusterName = "sf$Random"

  Write-Host "Enabling Active Directory RBAC here we go...." -ForegroundColor "cyan"
  Write-Color "  tenant: ", $tenantId -Color yellow, blue
  Write-Color "  replyUrl: ", $replyUrl -Color yellow, blue
  Write-Color "  cluster: ", $clusterName -Color yellow, blue

  & ./infrastructure/aadtool/SetupApplications.ps1 -TenantId $tenantId -ClusterName $clusterName -WebApplicationReplyUrl $replyUrl

  Write-Host "---------------------------------------------" -ForegroundColor "blue"
  Write-Host "Active Directory RBAC has been installed!!!!!" -ForegroundColor "red"
  Write-Host "---------------------------------------------" -ForegroundColor "blue"
}
