<#
.SYNOPSIS
  Infrastructure as Code Component
.DESCRIPTION
  Install a Virtual Machine Scale Set
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
  [string] $Prefix = $env:AZURE_GROUP
)

if (Test-Path ..\scripts\functions.ps1) { . ..\scripts\functions.ps1 }
if (Test-Path .\scripts\functions.ps1) { . .\scripts\functions.ps1 }
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
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Compute

##############################
## Deploy Template          ##
##############################
Write-Color -Text "Gathering information for Key Vault..." -Color Green
$VaultName = GetKeyVault $ResourceGroupName
$Cert = GetVaultCert $VaultName $Prefix
Write-Color -Text $CertId -Color White

Write-Color -Text "Retrieving Diagnostic Storage Account Parameters..." -Color Green
$StorageAccountName = GetStorageAccount $ResourceGroupName
Write-Color -Text $StorageAccountName -Color White


Write-Color -Text "Retrieving Network Parameters..." -Color Green
$Subnet = "defaultSubnet"
$VnetName = GetVirtualNetwork $ResourceGroupName
$LbName = GetLoadBalancer $ResourceGroupName
Write-Color -Text "$ResourceGroupName $VnetName $Subnet $LbName" -Color White


Write-Color -Text "Retrieving Credential Parameters..." -Color Green
$AdminUserName = (Get-AzureKeyVaultSecret -VaultName $VaultName -Name 'adminUserName').SecretValueText
$AdminPassword = (Get-AzureKeyVaultSecret -VaultName $VaultName -Name 'adminPassword').SecretValue
Write-Color -Text "$AdminUserName\*************" -Color White


Write-Color -Text "`r`n---------------------------------------------------- "-Color Yellow
Write-Color -Text "Deploying ", "$DEPLOYMENT-$Prefix ", "template..." -Color Green, Red, Green
Write-Color -Text "---------------------------------------------------- "-Color Yellow
New-AzureRmResourceGroupDeployment -Name $DEPLOYMENT-$Prefix `
  -TemplateFile $BASE_DIR\azuredeploy.json `
  -TemplateParameterFile $BASE_DIR\azuredeploy.parameters.json `
  -prefix $Prefix `
  -vnetName $VnetName -subnet $Subnet -lbName $LbName `
  -vaultName $VaultName -certificateUrlValue $Cert.SecretId -certificateThumbprint $Cert.Thumbprint `
  -adminUserName $AdminUserName -adminPassword $AdminPassword `
  -diagStorage $StorageAccountName[0] -logStorage $StorageAccountName[1] `
  -ResourceGroupName $ResourceGroupName
