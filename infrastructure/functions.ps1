$ErrorActionPreference = 'Stop'

$t = [Reflection.Assembly]::LoadWithPartialName("System.Web")
Write-Host "Loaded $($t.FullName)."


###############################
## FUNCTIONS                 ##
###############################
function Write-Color([String[]]$Text, [ConsoleColor[]]$Color = "White", [int]$StartTab = 0, [int] $LinesBefore = 0, [int] $LinesAfter = 0, [string] $LogFile = "", $TimeFormat = "yyyy-MM-dd HH:mm:ss") {
  # version 0.2
  # - added logging to file
  # version 0.1
  # - first draft
  #
  # Notes:
  # - TimeFormat https://msdn.microsoft.com/en-us/library/8kb3ddd4.aspx

  $DefaultColor = $Color[0]
  if ($LinesBefore -ne 0) {  for ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline } } # Add empty line before
  if ($StartTab -ne 0) {  for ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewLine } }  # Add TABS before text
  if ($Color.Count -ge $Text.Count) {
    for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine }
  }
  else {
    for ($i = 0; $i -lt $Color.Length ; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine }
    for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $DefaultColor -NoNewLine }
  }
  Write-Host
  if ($LinesAfter -ne 0) {  for ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" } }  # Add empty line after
  if ($LogFile -ne "") {
    $TextToFile = ""
    for ($i = 0; $i -lt $Text.Length; $i++) {
      $TextToFile += $Text[$i]
    }
    Write-Output "[$([datetime]::Now.ToString($TimeFormat))]$TextToFile" | Out-File $LogFile -Encoding unicode -Append
  }
}
function Get-ScriptDirectory {
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}
function GeneratePassword() {
  [System.Web.Security.Membership]::GeneratePassword(15, 2)
}
function LoginAzure() {
  Write-Color "Validating if you are logged in..." -Color Green
  $rmContext = Get-AzureRmContext

  if ($null -eq $rmContext.Account) {
    Write-Color "  you are not logged into Azure. Use Login-AzureRmAccount to log in first and optionally select a subscription" -Color Red
    exit
  }

  Write-Color "  account:      ", "'$($rmContext.Account.Id)'" -Color Yellow, Blue
  Write-Color "  subscription: ", "'$($rmContext.Subscription.Name)'" -Color Yellow, Blue
  Write-Color "  tenant:       ", "'$($rmContext.Tenant.Id)'" -Color Yellow, Blue
  Write-Color "  environment:  ", "'$($rmContext.Environment.Name)'" -Color Yellow, Blue
}
function CreateResourceGroup([string]$ResourceGroupName, [string]$Location) {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = LOCATION

  Get-AzureRmResourceGroup -Name $ResourceGroupName -ev notPresent -ea 0 | Out-null

  if ($notPresent) {
    Write-Host "Creating Resource Group $ResourceGroupName..." -ForegroundColor Yellow
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
  }
  else {
    Write-Color -Text "Resource Group ", "$ResourceGroupName ", "already exists." -Color Green, Red, Green
  }
}
function GetKeyVault([string]$ResourceGroupName) {
  # Required Argument $1 = RESOURCE_GROUP

  if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }

  return (Get-AzureRmKeyVault -ResourceGroupName $ResourceGroupName).VaultName
}
function Add-Secret ($ResourceGroupName, $SecretName, $SecretValue) {
  $KeyVault = Get-AzureRmKeyVault -ResourceGroupName $ResourceGroupName
  if (!$KeyVault) {
    Write-Error -Message "Key Vault in $ResourceGroupName not found. Please fix and continue"
    return
  }
  Write-Output "Saving Secret $SecretName..."
  $SecureSecretValue = ConvertTo-SecureString $SecretValue -AsPlainText -Force
  Set-AzureKeyVaultSecret -VaultName $KeyVault.VaultName -Name $SecretName -SecretValue $SecureSecretValue
}
function EnsureSelfSignedCertificate([string]$ResourceGroupName, [string]$CertName) {
  $localPath = "$PSScriptRoot\..\certs\$CertName.pfx"
  $existsLocally = Test-Path $localPath

  # create or read certificate
  if ($existsLocally) {
    Write-Color -Text "Local Certificate Found" -Color yellow
    $thumbprint = Get-Content "$PSScriptRoot\..\certs\$Certname.thumb.txt"
    $password = Get-Content "$PSScriptRoot\..\certs\$Certname.pwd.txt"
  }
  else {
    $thumbprint, $password, $localPath = CreateSelfSignedCertificate $CertName
  }

  $VaultName = GetKeyVault $ResourceGroupName
  $kvCert = GetVaultCert $VaultName $CertName
  if ($null -eq $kvCert) {
    ImportCertificateIntoKeyVault -ResourceGroupName $ResourceGroupName -Name $CertName -CertFilePath $localPath -CertPassword $password
  }
  else {
    Write-Color -Text "KeyVault Certificate Found." -Color yellow
  }
  $kvCert
}
function CreateSelfSignedCertificate([string]$DnsName) {
  Write-Host "Creating self-signed certificate with dns name $DnsName" -ForegroundColor Yellow

  $filePath = "$PSScriptRoot\..\certs\$DnsName.pfx"

  Write-Host "  generating password... " -NoNewline
  $certPassword = GeneratePassword
  Write-Host "$certPassword"

  Write-Host "  generating certificate... " -NoNewline
  $securePassword = ConvertTo-SecureString $certPassword -AsPlainText -Force
  $thumbprint = (New-SelfSignedCertificate -DnsName $DnsName -CertStoreLocation Cert:\CurrentUser\My -KeySpec KeyExchange).Thumbprint
  Write-Host "$thumbprint."

  Write-Host "  exporting to $filePath..."
  $certContent = (Get-ChildItem -Path cert:\CurrentUser\My\$thumbprint)
  $t = Export-PfxCertificate -Cert $certContent -FilePath $filePath -Password $securePassword
  Set-Content -Path "$PSScriptRoot\..\certs\$DnsName.thumb.txt" -Value $thumbprint
  Set-Content -Path "$PSScriptRoot\..\certs\$DnsName.pwd.txt" -Value $certPassword
  Write-Host "  exported."

  $thumbprint
  $certPassword
  $filePath
}
function GetVaultCert([string]$VaultName, [string]$CertName) {
  # Required Argument $1 = Vault Name
  # Required Argument $2 = Certificate Name

  if ( !$ResourceGroupName) { throw "VaultName Required" }
  if ( !$CertName) { throw "CertName Required" }

  return (Get-AzureKeyVaultCertificate -VaultName $VaultName -Name $CertName)
}
function ImportCertificateIntoKeyVault([string]$ResourceGroupName, [string]$Name, [string]$CertFilePath, [string]$CertPassword) {
  $KeyVaultName = GetKeyVault $ResourceGroupName
  Write-Color -Text "Importing certificate..." -Color yellow
  $securePassword = ConvertTo-SecureString $CertPassword -AsPlainText -Force
  Import-AzureKeyVaultCertificate -VaultName $KeyVaultName -Name $Name -FilePath $CertFilePath -Password $securePassword
}
function GetLogAnalyticsWorkspace([string]$ResourceGroupName) {
  # Required Argument $1 = RESOURCE_GROUP

  if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }

  return (Get-AzureRmOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName).Name
}
function GetLogAnalyticsWorkspaceId([string]$ResourceGroupName, $WorkspaceName) {
  # Required Argument $1 = RESOURCE_GROUP

  if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }

  return (Get-AzureRmOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName).CustomerId
}
function GetLogAnalyticsWorkspaceKey([string]$ResourceGroupName, $WorkspaceName) {
  # Required Argument $1 = RESOURCE_GROUP

  if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }

  return (Get-AzureRmOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $ResourceGroupName -Name $WorkspaceName).PrimarySharedKey
}
function GetStorageAccount([string]$ResourceGroupName) {
  # Required Argument $1 = RESOURCE_GROUP

  if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }

  return (Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName).StorageAccountName
}
function GetStorageAccountKey([string]$ResourceGroupName, $StorageAccountName) {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = STORAGE_ACCOUNT

  if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }
  if ( !$StorageAccountName) { throw "StorageAccountName Required" }

  return (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName).Value[0]
}
function GetVirtualNetwork([string]$ResourceGroupName) {
  # Required Argument $1 = RESOURCE_GROUP

  if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }

  return (Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName).Name
}
function GetLoadBalancer([string]$ResourceGroupName) {
  # Required Argument $1 = RESOURCE_GROUP

  if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }

  return (Get-AzureRmLoadBalancer -ResourceGroupName $ResourceGroupName).Name
}
function Unregister-ApplicationTypeCompletely([string]$ApplicationTypeName) {
  $type = Get-ServiceFabricApplicationType -ApplicationTypeName $ApplicationTypeName
  if ($type -eq $null) {
    Write-Color -Text "Application Type not installed" -Color yellow
  }
  else {
    $runningApps = Get-ServiceFabricApplication -ApplicationTypeName $ApplicationTypeName
    foreach ($app in $runningApps) {
      $uri = $app.ApplicationName.AbsoluteUri
      Write-Color -Text "Unregisgtering ", $uri -Color green, red

      $t = Remove-ServiceFabricApplication -ApplicationName $uri -ForceRemove -Verbose -Force
    }

    Write-Color -Text "Unregistering Application Type..." -Color yellow
    $t = Unregister-ServiceFabricApplicationType `
      -ApplicationTypeName $ApplicationTypeName -ApplicationTypeVersion $type.ApplicationTypeVersion `
      -Force -Confirm
  }
}
