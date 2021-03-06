<#
.SYNOPSIS
  Infrastructure as Code Component
.DESCRIPTION
  Install a Keyvault
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
  [string] $Prefix = $env:AZURE_GROUP,
  [string] $servicePrincipalAppId = $env:AZURE_PRINCIPAL,
  [string] $UserName = $env:AZURE_USERNAME,
  [string] $UserPass = $env:AZURE_PASSWORD
)

if (Test-Path ..\functions.ps1) { . ..\functions.ps1 }
if (Test-Path .\functions.ps1) { . .\functions.ps1 }
if (!$Subscription) { throw "Subscription Required" }
if (!$ResourceGroupName) { throw "Resource Group Required" }
if (!$Location) { throw "Location Required" }
if (!$Prefix) { throw "Prefix Required" }

if ((!$UserName) -or (!$UserPass)) {
  Write-Color -Text "`r`n---------------------------------------------------- "-Color Blue
  Write-Color -Text "Collecting Server Administrator Credentials... " -Color Red
  Write-Color -Text "---------------------------------------------------- "-Color Blue
  $credential = Get-Credential -Message "Enter Server Administrator Credentials"
  $UserName = $credential.GetNetworkCredential().UserName
  $UserPass = $credential.GetNetworkCredential().Password
}

###############################
## Azure Intialize           ##
###############################
$BASE_DIR = Get-ScriptDirectory
$DEPLOYMENT = Split-Path $BASE_DIR -Leaf
$ResourceGroupName = "$ResourceGroupName-$Environment"
LoginAzure
CreateResourceGroup $ResourceGroupName $Location

Write-Color -Text "Registering Provider..." -Color Yellow
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.KeyVault


##############################
## Deploy Template          ##
##############################
Write-Color -Text "Gathering Service Principal..." -Color Green
if ($servicePrincipalAppId) {
  $ID = $servicePrincipalAppId
}
else {
  $ACCOUNT = $(Get-AzureRmContext).Account
  if ($ACCOUNT.Type -eq 'User') {
    $USER = Get-AzureRmADUser -UPN $(Get-AzureRmContext).Account
    $ID = $USER.Id.Guid
  }
  else {
    $ID = Read-Host 'Input your Service Principal.'
  }
}

Write-Color -Text "Key Vault Service Principal: ", "$ID" -Color Green, Red

Write-Color -Text "`r`n---------------------------------------------------- "-Color Yellow
Write-Color -Text "Deploying ", "$DEPLOYMENT-$Prefix ", "template..." -Color Green, Red, Green
Write-Color -Text "---------------------------------------------------- "-Color Yellow
New-AzureRmResourceGroupDeployment -Name $DEPLOYMENT-$Prefix `
  -TemplateFile $BASE_DIR\azuredeploy.json `
  -TemplateParameterFile $BASE_DIR\azuredeploy.parameters.json `
  -prefix $Prefix `
  -servicePrincipalAppId $ID `
  -adminUserName $UserName -adminPassword $UserPass  `
  -ResourceGroupName $ResourceGroupName `
  -Verbose

# For development purposes, we create a self-signed cluster certificate here.
Write-Color -Text "Preparing Certificates..." -Color Yellow
$cert = EnsureSelfSignedCertificate $ResourceGroupName $Prefix

$Env:ThumbPrint = $cert.Thumbprint

#Load up the Vault for Pipeline Usage

Add-Secret $ResourceGroupName "azureLocation" $env:AZURE_LOCATION
Add-Secret $ResourceGroupName "azureGroup" $env:AZURE_GROUP
Add-Secret $ResourceGroupName "azureRandom" $env:AZURE_RANDOM
Add-Secret $ResourceGroupName "azureEnvironment" $Environment

Add-Secret $ResourceGroupName "certThumbprint" $cert.Thumbprint
Add-Secret $ResourceGroupName "certSecretId" $cert.SecretId

Add-Secret $ResourceGroupName "analyticsId" $env:AZURE_ANALYTICS
Add-Secret $ResourceGroupName "analyticsKey" $env:AZURE_ANALYTICS_KEY

Add-Secret $ResourceGroupName "fabricTier" $env:FABRIC_TIER
Add-Secret $ResourceGroupName "fabricNodeCount" $env:FABRIC_NODE_COUNT
