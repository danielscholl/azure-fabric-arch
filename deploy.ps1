param(
  [Parameter(Mandatory = $true)] [string] $Environment,
  [string] $Location = $env:AZURE_LOCATION,
  [string] $Name = "SimpleApp.SfProd",
  [string] $Package = "simpleapp"
)
$PkgPath = "$PSScriptRoot\pkgs\$Package"

if (Test-Path "$PSScriptRoot\.env_$Environment.ps1") { . "$PSScriptRoot\.env_$Environment.ps1" }
if (Test-Path "$PSScriptRoot\scripts\functions.ps1") { . "$PSScriptRoot\scripts\functions.ps1" }

Write-Color -Text "Deploying Service Fabric Package here we go...." -Color "cyan"

Write-Color -Text "Connecting to the ", $Environment, " environment" -Color "green", "red", "green"
Connect-ServiceFabricCluster `
  -ConnectionEndpoint $Env:Endpoint `
  -FindType FindByThumbprint -FindValue $Env:ThumbPrint `
  -X509Credential `
  -ServerCertThumbprint $Env:ThumbPrint `
  -StoreLocation CurrentUser -StoreName My


Write-Color -Text "Unregistering ", $Name, " if present..."   -Color "green", "red", "green"
Unregister-ApplicationTypeCompletely $Name

Write-Color -Text "Deploying Application to the cluster..." -Color yellow
Copy-ServiceFabricApplicationPackage -ApplicationPackagePath $PkgPath -ApplicationPackagePathInImageStore $Name -TimeoutSec 1800 -ShowProgress
Register-ServiceFabricApplicationType -ApplicationPathInImageStore $Name
New-ServiceFabricApplication -ApplicationName "fabric:/$Name" -ApplicationTypeName $Name -ApplicationTypeVersion "1.0.0"
