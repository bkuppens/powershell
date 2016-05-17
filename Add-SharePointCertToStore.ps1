<#
.SYNOPSIS
	Adds the "SharePoint Root Authority' certificate to the Trusted Root CA on the local SharePoint server.

.DESCRIPTION
	Adds the "SharePoint Root Authority' certificate to the Trusted Root CA on the local SharePoint server.

.NOTES
	File Name: Add-SharePointCertToStore.ps1
	Author   : Bart Kuppens
	Version  : 1.0
#>

# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell
}

$RootCert = (Get-SPCertificateAuthority).RootCertificate

if ($RootCert -eq $null)
{
	Write-Output "Unable to get the SharePoint Root Certificate! Halting execution."
}
else
{
	[void][System.Reflection.Assembly]::LoadWithPartialName("System.Security")
	$store = get-item Cert:\LocalMachine\Root
	if ($store -ne $null)
	{
		$store.Open("ReadWrite")
		$store.Add($RootCert)
		$store.Close()
	}
}