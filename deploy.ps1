param(
  [Parameter(Mandatory = $true)] [string] $Environment,
  [string] $Location = $env:AZURE_LOCATION,
  [Parameter(Mandatory = $true)] [string] $Name
)
$PkgPath = "$PSScriptRoot\pkgs\$Name"
$TypeName = "{0}Type" -f $Name

if (Test-Path "$PSScriptRoot\.env_$Environment.ps1") { . "$PSScriptRoot\.env_$Environment.ps1" }
if (Test-Path "$PSScriptRoot\infrastructure\functions.ps1") { . "$PSScriptRoot\infrastructure\functions.ps1" }

if($Name -eq "Traefik") {
  $keyPath = "$PSScriptRoot\pkgs\Traefik\TraefikPkg\code\certs\servicefabric.key"
  $crtPath = "$PSScriptRoot\pkgs\Traefik\TraefikPkg\code\certs\servicefabric.crt"
  $ClusterName = "sf$env:AZURE_RANDOM"

  Write-Color "Preparing Traefix Certificates..." -Color yellow
  $certPath = "$PSScriptRoot\certs\$ClusterName.pfx"
  $pass = Get-Content "$PSScriptRoot\certs\$ClusterName.pwd.txt"
  openssl pkcs12 -in $certPath -nocerts -nodes -out $keyPath -passin pass:$pass
  openssl pkcs12 -in $certPath -clcerts -nokeys -out $crtPath -passin pass:$pass
}

Write-Color -Text "Deploying Service Fabric Package here we go...." -Color "cyan"

Write-Color -Text "Connecting to the ", $Environment, " environment" -Color "green", "red", "green"
Connect-ServiceFabricCluster `
  -ConnectionEndpoint $Env:Endpoint `
  -FindType FindByThumbprint -FindValue $Env:ThumbPrint `
  -X509Credential `
  -ServerCertThumbprint $Env:ThumbPrint `
  -StoreLocation CurrentUser -StoreName My


Write-Color -Text "Unregistering ", $Name, " if present..."   -Color "green", "red", "green"
Unregister-ApplicationTypeCompletely $TypeName

Write-Color -Text "Deploying Application to the cluster..." -Color yellow
Copy-ServiceFabricApplicationPackage -ApplicationPackagePath $PkgPath -ApplicationPackagePathInImageStore $TypeName -TimeoutSec 1800 -ShowProgress
Register-ServiceFabricApplicationType -ApplicationPathInImageStore $TypeName
New-ServiceFabricApplication -ApplicationName "fabric:/$TypeName" -ApplicationTypeName $TypeName -ApplicationTypeVersion "1.0.0"
