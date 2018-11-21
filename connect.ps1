<#
.SYNOPSIS
  Connect to the Service Fabric
.DESCRIPTION
  This Script will connect to the Desired Service Fabric Environment


.EXAMPLE
  .\connect.ps1
  Version History
  v1.0   - Initial Release
#>
#Requires -Version 5.1
#Requires -Module @{ModuleName='AzureRM.Resources'; ModuleVersion='5.0'}

param(
  [Parameter(Mandatory = $true)]
  [string] $Environment
)

if (Test-Path "$PSScriptRoot\.env_$Environment.ps1") { . "$PSScriptRoot\.env_$Environment.ps1" }

Get-ChildItem Env:ThumbPrint
Get-ChildItem Env:Endpoint

Connect-ServiceFabricCluster `
  -ConnectionEndpoint $Env:Endpoint `
  -FindType FindByThumbprint `
  -FindValue $Env:ThumbPrint `
  -X509Credential `
  -ServerCertThumbprint $Env:ThumbPrint `
  -StoreLocation CurrentUser `
  -StoreName My
