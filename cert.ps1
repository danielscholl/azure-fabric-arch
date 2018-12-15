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
  [Parameter(Mandatory = $true)] [string] $Environment
)

# Clear any existing environment settings.
$Env:AZURE_RANDOM = [string]::Empty
if (Test-Path "$PSScriptRoot\.env_$Environment.ps1") { . "$PSScriptRoot\.env_$Environment.ps1" }

$filePath = "$PSScriptRoot\certs\sf$env:AZURE_RANDOM.pfx"
[System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($filePath))
