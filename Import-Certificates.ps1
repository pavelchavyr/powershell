<#
.SYNOPSIS
    Import multiple certificates to Certificate Store
.DESCRIPTION
    This script installs imports certificates to Certificate Stor so OS can trust them.
.PARAMETER Certificates
    The array of certificates content in PEM format
.PARAMETER DataSourceUrl
    The Prometheus endpoint for metrics (without protocol)
.PARAMETER DataSourceSecret
    The Prometheus endpoint password (Basic-Auth)
.PARAMETER CertStoreLocation
    Certificate Store Location (default: 'Cert:\LocalMachine\Root')
.PARAMETER FilePath
    File Path for temporary certificate file storage (default: 'C:\temp\CertToImport.cer')
.EXAMPLE
    .\Import-Certificates.ps1 -Certificates "$firstCert","$secondCert"
#>

param(
  [array]$Certificates = "@'
  -----BEGIN CERTIFICATE-----
MIIDkjCCAnqgAwIBAgIQFRFWqq9fFZ5IQTSw/DVTqjANBgkqhkiG9w0BAQ0FADBI
MRUwEwYKCZImiZPyLGQBGRYFbG9jYWwxEzARBgoJkiaJk/IsZAEZFgNBSEkxGjAY
BgNVBAMTEUFISS1DQS1TUlYxMi1ST09UMB4XDTIwMDEwNjEzMDAwNVoXDTI2MDEw
NjEzMTAwNFowSDEVMBMGCgmSJomT8ixkARkWBWxvY2FsMRMwEQYKCZImiZPyLGQB
GRYDQUhJMRowGAYDVQQDExFBSEktQ0EtU1JWMTItUk9PVDCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBANk3hGCNT0JTN9Df2T23jHPQmQHMgl40mVZn/sxE
RVF8DezyiS9nLZ5JaGkwG9/JCZub2eh2wO9i4Efg20PBjTIQL8xoXIFSx4ulwhLI
D1uYDiWkaMYuAi8hTkywck134KG4UkKegEXHtJ1xjsMETpp49vbRLPLcuFlqi/dr
6UmgJh2G0e1uZMgBgG+XbP+/PmHhh1+xsmqiYvoZQgilaqv2+8HAvLzwORGXog+5
TVyzG8vRGx8FEuEa0ubV8RMPxyw6tKU+/hpBeRl6RloqiUAOrGLVg66P+hfTRqGE
BPSbkcr1mcrJTFFKpokendQ+JIRRRhJ+GJJe7SK2GxLZDL8CAwEAAaN4MHYwCwYD
VR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFAqyLmg3THc79M3r
LrVomV2y7JNvMBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUCBBYEFCrT
KExpCnXKz9o3UIVU1yzQ+UXSMA0GCSqGSIb3DQEBDQUAA4IBAQBBUB2YSnMoWI5Y
KFl/Dp1osRmgOtYB5mi1ITf/bR5ffZ5j0K8L/6mL2hGzXyyb87cNkVf2bnnoJ+EP
Ue8s9+isdV20nW1uQPae+FS1/3Q3nGYgyMo/DgHa89uWE8lidQyOk89SR5GYxszZ
Y+VVzEV81SVUC5mGifdZh/pKMunAxHtTXP03f3NrLh8rqjLvQWKnSkPTlrtAYisR
1NZq6CeLFIbBxa+QgZbSka3GEh4zkIafK1zAZ5qeXfZw4LKSyLtacMZ3vxZIIN06
yrsh3RsGuyanCdNcHfyJ2e826qcoSiBgBooOPHbTBLEUlZ0pfAeJhGlDCuknC7ku
e5xCvzC/
-----END CERTIFICATE-----
  '@",
  [string]$CertStoreLocation = 'Cert:\LocalMachine\Root',
  [string]$DataSourceUrl = "prometheus.monitoring.local",
  [string]$DataSourceSecret = "password",
  [string]$FilePath = '.\CertToImport.cer'
)

foreach ($Certificate in $Certificates) {
  Write-Host "Importing Certificate to $CertStoreLocation"
  $Certificate | Out-File -FilePath $FilePath
  Import-Certificate -FilePath $FilePath -CertStoreLocation $CertStoreLocation
  Remove-Item -Path $FilePath
  Write-Host "Import is done"
}

.\Install-MonitoringAgents.ps1 -DataSourceUrl "$DataSourceUrl" -DataSourceSecret "$DataSourceSecret"
