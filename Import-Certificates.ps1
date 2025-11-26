<#
.SYNOPSIS
    Import multiple certificates to Certificate Store
.DESCRIPTION
    This script installs imports certificates to Certificate Stor so OS can trust them.
.PARAMETER Certificates
    The array of certificates content in PEM format
.PARAMETER CertStoreLocation
    Certificate Store Location (default: 'Cert:\LocalMachine\Root')
.PARAMETER FilePath
    File Path for temporary certificate file storage (default: 'C:\temp\CertToImport.cer')
.EXAMPLE
    .\Import-Certificates.ps1 -Certificates "$firstCert","$secondCert"
#>

param(
  [array]$Certificates = "",
  [string]$CertStoreLocation = 'Cert:\LocalMachine\Root',
  [string]$FilePath = '.\CertToImport.cer'
)

foreach ($Certificate in $Certificates) {
  Write-Host "Importing Certificate to $CertStoreLocation"
  $Certificate | Out-File -FilePath $FilePath
  Import-Certificate -FilePath $FilePath -CertStoreLocation $CertStoreLocation
  Remove-Item -Path $FilePath
  Write-Host "Import is done"
}
