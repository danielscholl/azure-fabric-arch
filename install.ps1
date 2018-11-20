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
  [string] $ResourceGroupName = "$env:AZURE_RANDOM-$env:AZURE_GROUP",
  [string] $Location = $env:AZURE_LOCATION,
  [string] $Prefix = $env:AZURE_GROUP,
  [string] $Random = $env:AZURE_RANDOM
)

if (Test-Path "$PSScriptRoot\.env.ps1") { . "$PSScriptRoot\.env.ps1" }
if (Test-Path "$PSScriptRoot\scripts\functions.ps1") { . "$PSScriptRoot\scripts\functions.ps1" }

Get-ChildItem Env:AZURE*

Write-Host "Install Base Resources here we go...." -ForegroundColor "green"
& ./iac-keyvault/install.ps1 -Prefix "sf$Random"
& ./iac-storage/install.ps1 -Prefix "sf$Random" -Suffix "logs"
& ./iac-storage/install.ps1 -Prefix "sf$Random" -Suffix "diag"
& ./iac-network/install.ps1 -Prefix "sf$Random"
& ./iac-publicLB/install.ps1 -Prefix "sf$Random"
& ./iac-serviceFabric/install.ps1 -Prefix "sf$Random"

$Endpoint = "sf$Random.eastus2.cloudapp.azure.com:19000"
Write-Host "Endpoint: $Endpoint" -ForegroundColor "cyan"
Write-Host "Thumbpoint: $env:AZURE_SF_THUMBPRINT" -ForegroundColor "cyan"

Write-Host "
Connect-ServiceFabricCluster ``
  -ConnectionEndpoint $Endpoint ``
  -FindType FindByThumbprint ``
  -FindValue $ThumbPrint ``
  -X509Credential ``
  -ServerCertThumbprint $ThumbPrint ``
  -StoreLocation CurrentUser ``
  -StoreName My
" -ForegroundColor "cyan"
