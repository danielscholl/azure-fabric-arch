<#
.SYNOPSIS
  Infrastructure as Code Component
.DESCRIPTION
  Install a StorageAccount
.EXAMPLE
  .\install.ps1
  Version History
  v1.0   - Initial Release
#>
#Requires -Version 5.1
#Requires -Module @{ModuleName='AzureRM.Resources'; ModuleVersion='5.0'}

Param(
  [string] $Subscription = $env:AZURE_SUBSCRIPTION,
  [string] $ResourceGroupName = "$env:AZURE_RANDOM-$env:AZURE_GROUP",
  [string] $Location = $env:AZURE_LOCATION,
  [string] $Prefix = $env:AZURE_GROUP,
  [string] $Suffix = ""
)

if (Test-Path ..\functions.ps1) { . ..\functions.ps1 }
if (Test-Path .\functions.ps1) { . .\functions.ps1 }
if ( !$Subscription) { throw "Subscription Required" }
if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }
if ( !$Location) { throw "Location Required" }

###############################
## Azure Intialize           ##
###############################
$BASE_DIR = Get-ScriptDirectory
$DEPLOYMENT = Split-Path $BASE_DIR -Leaf
LoginAzure
CreateResourceGroup $ResourceGroupName $Location

Write-Color -Text "Registering Provider..." -Color Yellow
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Storage

##############################
## Deploy Template          ##
##############################
Write-Color -Text "`r`n---------------------------------------------------- "-Color Yellow
Write-Color -Text "Deploying ", "$DEPLOYMENT-$Prefix ", "template..." -Color Green, Red, Green
Write-Color -Text "---------------------------------------------------- "-Color Yellow
New-AzureRmResourceGroupDeployment -Name $DEPLOYMENT-$Prefix `
  -TemplateFile $BASE_DIR\azuredeploy.json `
  -TemplateParameterFile $BASE_DIR\azuredeploy.parameters.json `
  -prefix $Prefix -suffix $Suffix `
  -ResourceGroupName $ResourceGroupName `
  -Verbose
