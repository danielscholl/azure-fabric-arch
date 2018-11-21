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
  [boolean] $Base = $false,
  [ValidateSet('none','publicLB')] [string] $Routing = "none",
  [boolean] $Cluster = $false,
  [Parameter(Mandatory = $true)] [string] $Environment,

  [string] $ResourceGroupName = "$env:AZURE_RANDOM-$env:AZURE_GROUP",
  [string] $Location = $env:AZURE_LOCATION,
  [string] $Prefix = $env:AZURE_GROUP,
  [string] $Random = $env:AZURE_RANDOM
)

if (Test-Path "$PSScriptRoot\scripts\functions.ps1") { . "$PSScriptRoot\scripts\functions.ps1" }

# Clear any existing environment settings.
$Env:AZURE_TENANT = [string]::Empty
$Env:AZURE_SUBSCRIPTION = [string]::Empty
$Env:AZURE_PRINCIPAL = [string]::Empty
$Env:AZURE_LOCATION = [string]::Empty
$Env:AZURE_GROUP = [string]::Empty
$Env:AZURE_RANDOM = [string]::Empty
$Env:AZURE_USERNAME = [string]::Empty
$Env:AZURE_PASSWORD = [string]::Empty
$Env:FABRIC_TIER = [string]::Empty
$Env:FABRIC_NODE_COUNT = 0

# Load Project Environment Settings
if (Test-Path "$PSScriptRoot\.env_$Environment.ps1") { . "$PSScriptRoot\.env_$Environment.ps1" }

# Display Project Environment Settings
Get-ChildItem Env:AZURE*
Get-ChildItem Env:FABRIC*

if ($Base -eq $true) {
  Write-Host "Install Base Resources here we go...." -ForegroundColor "cyan"
  & ./iac-keyvault/install.ps1 -Prefix "sf$Random"
  & ./iac-storage/install.ps1 -Prefix "sf$Random"
  & ./iac-network/install.ps1 -Prefix "sf$Random"

  Write-Host "---------------------------------------------" -ForegroundColor "blue"
  Write-Host "Base Components have been installed!!!!!" -ForegroundColor "red"
  Write-Host "---------------------------------------------" -ForegroundColor "blue"
}

if ($Routing -eq "publicLB") {
  Write-Host "Install Routing Resources here we go...." -ForegroundColor "cyan"
  & ./iac-publicLB/install.ps1 -Prefix "sf$Random"

  Write-Host "---------------------------------------------" -ForegroundColor "blue"
  Write-Host "Routing Components have been installed!!!!!" -ForegroundColor "red"
  Write-Host "---------------------------------------------" -ForegroundColor "blue"
}

if ($Cluster -eq $true) {
  Write-Host "Install Cluster Resources here we go...." -ForegroundColor "cyan"
  & ./iac-serviceFabric/install.ps1 -Prefix "sf$Random"

  Write-Host "---------------------------------------------" -ForegroundColor "blue"
  Write-Host "Cluster Components have been installed!!!!!" -ForegroundColor "red"
  Write-Host "---------------------------------------------" -ForegroundColor "blue"

  $env:Endpoint = "sf$Random.eastus2.cloudapp.azure.com:19000"
  Write-Color -Text "Endpoint = ", $env:Endpoint -Color green, red
}
