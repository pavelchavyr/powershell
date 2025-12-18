param(
    [Parameter(Mandatory = $true)]
    [String] $appName
)

Connect-ServiceFabricCluster

$app = Get-ServiceFabricApplication -ApplicationName $appName -ErrorAction SilentlyContinue

if ($app) {
    Write-Host "Application $appName is installed and running."
} else {
    Write-Host "Application $appName is not found in the cluster."
    exit
}

$appParams = $app.ApplicationParameters

$currentCert = ($appParams | Where-Object {$_.Name -eq "HttpsCertHash"}).Value
$certSubject = (Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object {$_.Thumbprint -eq $currentCert}).Subject
$thumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My -Recurse | Where-Object {$_.Subject -eq $certSubject} | Sort-Object -Property NotAfter -Descending)[0].Thumbprint

if ($thumbprint -eq $currentCert) {
  Write-Host "App uses the latest certificate. No update is required"
  exit
}

$needsUpdate = $false
For ($i=0; $i -le $appParams.count; $i++) {
    # loop through app params, find ignoreremoteCertificateNameMismatch
	if ($appParams[$i].Name -eq "Common_IgnoreRemoteCertificateNameMismatch") {

		# check if this value is empty and just add the thumbprint if so
		if ($appParams[$i].Value -eq "" -Or $null -eq $appParams[$i].Value) {
			$appParams[$i].Value = $thumbprint
			"No Trusted Certs currently exist. Thumbprint must be added as a Trusted Cert first"
			$needsUpdate = $true
			break
		}

		# if this point is reached, then thumbprints exist already in the list
		# need to check if the list is comma-separated (for older installations)
		$needsDelimiterUpdate = $false
		$valueWithCorrectDelimeter = $appParams[$i].Value
		if ($appParams[$i].Value.Contains(",")) {
			$needsDelimiterUpdate = $true
			$valueWithCorrectDelimeter = $appParams[$i].Value.Replace(",", "|")
		}
		
		# at this point, there are no commas, only either 1 thumbprint or multiple, separated by |
		# find if user-input thumbprint exists in list of existing thumbprints
		$thumbprintArray = $valueWithCorrectDelimeter.Split("|")
		$certExists = $false
		For ($j=0; $j -le $thumbprintArray.count; $j++) {
			if ($thumbprintArray[$j] -eq $thumbprint) {
				"Thumbprint exists in list of Common_IgnoreRemoteCertificateNameMismatch"
				$certExists = $true
				break
			}
		}

		# if user-input thumbprint does not currently exist, we must append it to the list
		if (!($certExists)) {
			$newValue = "{0}|{1}" -f $valueWithCorrectDelimeter, $thumbprint
			$appParams[$i].Value = $newValue
			$needsUpdate = $true
		} elseif ($needsDelimiterUpdate -eq $true) {
			$appParams[$i].Value = $valueWithCorrectDelimeter
			$needsUpdate = $true
		}
	}
}

if ($needsUpdate -eq $false) {
	"No need to update Application Parameter Common_IgnoreRemoteCertificateNameMismatch"
} else {
	"Starting update process for Application Parameter Common_IgnoreRemoteCertificateNameMismatch"
	#make app params into a hash table (thanks Stack Overflow)
	$appParams | foreach -begin {$h=@{}} -process {$h."$($_.Name)" = $_.Value} -end {$h}

	Start-ServiceFabricApplicationUpgrade -ApplicationName $appName -ApplicationTypeVersion $app.ApplicationTypeVersion -ApplicationParameter $h -Monitored -FailureAction Rollback -ForceRestart

	$paramUpdated = $false
	start-sleep -Seconds 30
	do {
		$progress = Get-ServiceFabricApplicationUpgrade -ApplicationName $appName
		"waiting for Params update to complete"
		$progress
		if ($progress.UpgradeState -eq "RollingForwardCompleted") {
			"Params Update completed"
			$paramUpdated = $true
		}
		start-sleep -Seconds 30
	} while(!($paramUpdated))
}

For ($i=0; $i -le $appParams.count; $i++) {
	if ($appParams[$i].Name -eq "HttpsCertHash") {
		$appParams[$i].Value = $thumbprint
	}
}
"Starting Update Process for HttpsCertHash"
#make app params into a hash table (thanks Stack Overflow)
$appParams | foreach -begin {$h=@{}} -process {$h."$($_.Name)" = $_.Value} -end {$h}

Start-ServiceFabricApplicationUpgrade -ApplicationName $appName -ApplicationTypeVersion $app.ApplicationTypeVersion -ApplicationParameter $h -Monitored -FailureAction Rollback -ForceRestart

$paramUpdated = $false
start-sleep -Seconds 30
do {
	$progress = Get-ServiceFabricApplicationUpgrade -ApplicationName $appName
	"waiting for Params update to complete"
	$progress
	if ($progress.UpgradeState -eq "RollingForwardCompleted") {
		"Certificate Rollover completed"
		$paramUpdated = $true
	}
	start-sleep -Seconds 30
} while(!($paramUpdated))

