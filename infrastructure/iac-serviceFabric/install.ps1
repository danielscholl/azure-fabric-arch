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
  [Parameter(Mandatory = $true)] [string] $Environment,
  [string] $ResourceGroupName = "$env:AZURE_RANDOM-$env:AZURE_GROUP",
  [string] $Location = $env:AZURE_LOCATION,
  [string] $Prefix = $env:AZURE_GROUP,
  [string] $Analytics = $env:AZURE_ANALYTICS,
  [string] $AnalyticsKey = $env:AZURE_ANALYTICS_KEY,
  [ValidateSet('bronze','silver')]
  [string] $Level = $env:FABRIC_TIER,
  [int] $Instance = $env:FABRIC_NODE_COUNT,
  [string] $Tenant = $env:AZURE_TENANT,
  [string] $ClusterAppId = $env:CLUSTER_APP,
  [string] $ClientAppId = $env:CLIENT_APP
)

if (Test-Path ..\functions.ps1) { . ..\functions.ps1 }
if (Test-Path .\functions.ps1) { . .\functions.ps1 }
if ( !$Subscription ) { throw "Subscription Required" }
if ( !$ResourceGroupName ) { throw "ResourceGroupName Required" }
if ( !$Location ) { throw "Location Required" }

$armParameters = @{
  prefix = $Prefix;
  dnsName = "$Prefix-$Environment";
  vmCount = $Instance;
  omsWorkspaceId = $Analytics;
  omsWorkspaceKey = $AnalyticsKey;
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
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Compute

##############################
## GATHER DATA              ##
##############################
Write-Color -Text "Gathering information for Key Vault..." -Color Green
$VaultName = GetKeyVault $ResourceGroupName
Write-Color -Text $VaultName -Color White
$armParameters.vaultName = $VaultName

Write-Color -Text "Gathering information for Cluster Certificate..." -Color Green
$Cert = GetVaultCert $VaultName $Prefix
Write-Color -Text $Cert.Name -Color White
$armParameters.certificateUrlValue = $Cert.SecretId
$armParameters.certificateThumbprint = $Cert.Thumbprint;

Write-Color -Text "Retrieving Diagnostic Storage Account Parameters..." -Color Green
$StorageAccountName = GetStorageAccount $ResourceGroupName
Write-Color -Text $StorageAccountName -Color White
$armParameters.storageAccount = $StorageAccountName

Write-Color -Text "Retrieving Network Parameters..." -Color Green
$Subnet = "defaultSubnet"
$VnetName = GetVirtualNetwork $ResourceGroupName
$LbName = GetLoadBalancer $ResourceGroupName
Write-Color -Text "$ResourceGroupName $VnetName $Subnet $LbName" -Color White
$armParameters.vnetName = $VnetName
$armParameters.subnet = $Subnet;
$armParameters.lbName = $LbName;

Write-Color -Text "Retrieving Credential Parameters..." -Color Green
$AdminUserName = (Get-AzureKeyVaultSecret -VaultName $VaultName -Name 'adminUserName').SecretValueText
$AdminPassword = (Get-AzureKeyVaultSecret -VaultName $VaultName -Name 'adminPassword').SecretValue
Write-Color -Text "$AdminUserName\*************" -Color White
$armParameters.adminUserName = $AdminUserName
$armParameters.adminPassword = $AdminPassword

##############################
## Deploy Template          ##
##############################
$TEMPLATE = $Level
$Env:CLUSTER_APP
$Env:CLIENT_APP

if ( $ClusterAppId -and $ClientAppId ) {
  $TEMPLATE = $Level + "RBAC"
  $armParameters.tenantId = $Tenant
  $armParameters.clusterApplicationId = $ClusterAppId;
  $armParameters.clientApplicationId = $ClientAppId;
}

Write-Color -Text "`r`n---------------------------------------------------- "-Color Yellow
Write-Color -Text "Deploying ", "$DEPLOYMENT-$Prefix ", "template..." -Color Green, Red, Green
Write-Color -Text "---------------------------------------------------- "-Color Yellow
$armParameters

New-AzureRmResourceGroupDeployment -Name $DEPLOYMENT-$Prefix `
-TemplateFile $BASE_DIR\$TEMPLATE.json `
-TemplateParameterObject $armParameters `
-ResourceGroupName $ResourceGroupName `
-Verbose

