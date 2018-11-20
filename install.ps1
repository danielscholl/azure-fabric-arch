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
  [string] $Random = $env:AZURE_RANDOM,
  [ValidateSet('bronze','silver')]
  [String] $Level = "bronze"
)

if (Test-Path "$PSScriptRoot\.env.ps1") { . "$PSScriptRoot\.env.ps1" }
if (Test-Path "$PSScriptRoot\scripts\functions.ps1") { . "$PSScriptRoot\scripts\functions.ps1" }

Get-ChildItem Env:AZURE*

Write-Host "Install Base Resources here we go...." -ForegroundColor "green"
& ./iac-keyvault/install.ps1 -Prefix "sf$Random"
& ./iac-storage/install.ps1 -Prefix "sf$Random"
& ./iac-network/install.ps1 -Prefix "sf$Random"
& ./iac-publicLB/install.ps1 -Prefix "sf$Random"
& ./iac-serviceFabric/install.ps1 -Prefix "sf$Random" -Level $Level

$Endpoint = "sf$Random.eastus2.cloudapp.azure.com:19000"
Write-Color -Text "Endpoint: ", $Endpoint -Color green, red
Write-Color -Text "ThumbPrint: ", $env:AZURE_SF_THUMBPRINT -Color green, red

Write-Color -Text "
Connect-ServiceFabricCluster ``
  -ConnectionEndpoint $Endpoint ``
  -FindType FindByThumbprint ``
  -FindValue $ThumbPrint ``
  -X509Credential ``
  -ServerCertThumbprint $ThumbPrint ``
  -StoreLocation CurrentUser ``
  -StoreName My" -Color cyan
