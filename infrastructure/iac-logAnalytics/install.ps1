<#
.SYNOPSIS
  Infrastructure as Code Component
.DESCRIPTION
  Install a LogAnalytics Account
.EXAMPLE
  .\install.ps1
  Version History
  v1.0   - Initial Release
#>
#Requires -Version 5.1
#Requires -Module @{ModuleName='AzureRM.Resources'; ModuleVersion='5.0'}

Param(
  [string] $Subscription = $env:AZURE_SUBSCRIPTION,
  [Parameter(Mandatory = $true)] [string] $Environment,
  [string] $ResourceGroupName = "$env:AZURE_RANDOM-$env:AZURE_GROUP",
  [string] $Location = $env:AZURE_LOCATION,
  [string] $Prefix = $env:AZURE_GROUP
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
$ResourceGroupName = "$ResourceGroupName-$Environment"
LoginAzure
CreateResourceGroup $ResourceGroupName $Location

Write-Color -Text "Registering Provider..." -Color Yellow
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Storage

##############################
## GATHER DATA              ##
##############################
Write-Color -Text "Retrieving Diagnostic Storage Account Parameters..." -Color Green
$StorageAccountName = GetStorageAccount $ResourceGroupName
Write-Color -Text $StorageAccountName -Color White

##############################
## Deploy Template          ##
##############################
Write-Color -Text "`r`n---------------------------------------------------- "-Color Yellow
Write-Color -Text "Deploying ", "$DEPLOYMENT-$Prefix ", "template..." -Color Green, Red, Green
Write-Color -Text "---------------------------------------------------- "-Color Yellow
New-AzureRmResourceGroupDeployment -Name $DEPLOYMENT-$Prefix `
  -TemplateFile $BASE_DIR\azuredeploy.json `
  -TemplateParameterFile $BASE_DIR\azuredeploy.parameters.json `
  -prefix $Prefix `
  -ResourceGroupName $ResourceGroupName `
  -storageAccountName $StorageAccountName `
  -Verbose
