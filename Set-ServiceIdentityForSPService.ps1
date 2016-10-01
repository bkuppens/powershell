<#
.SYNOPSIS
	Specify a new service identity for a SharePoint Service.
	
.DESCRIPTION
	Specify a new service identity for a SharePoint Service.
	
.NOTES
	File Name: Set-ServiceIdentityForSPService.ps1
	Author   : Bart Kuppens
	Version  : 1.1
	
.PARAMETER ServiceName
	Specifies the name of the SharePoint service.

.PARAMETER TypeName
    Specifies the typename of the SharePoint service.

.PARAMETER LocalIdentity
    If specified, will assign a local identity to the service.

.PARAMETER DomainIdentity
    If specified, will assign a domain account to the service.

.PARAMETER Identity
    Specifies the name of the local identity (LocalService, LocalSystem or NetworkService).

.PARAMETER AccountName
    Specifies the name of a managed account to use as identity.

.EXAMPLE
	PS > .\Set-ServiceIdentityForSPService.ps1 -ServiceName "c2wts" -LocalIdentity -Identity LocalService

    DESCRIPTION
    -----------
    Will change the identity of the c2wts service to LocalService

.EXAMPLE
    PS > .\Set-ServiceIdentityForSPService.ps1 -ServiceName "c2wts" -DomainIdentity -AccountName "westeros\svc_spservice"

    DESCRIPTION
    -----------
    Will change the identity of the c2wts service to westeros\svc_spservice
#>
[CmdletBinding()]
param(
	[parameter(ParameterSetName="ServiceNameLocal",Mandatory=$true,ValueFromPipeline=$false)]
    [parameter(ParameterSetName="ServiceNameDomain",Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
	[string]$ServiceName,
	[parameter(ParameterSetName="TypeNameLocal",Mandatory=$true,ValueFromPipeline=$false)]
    [parameter(ParameterSetName="TypeNameDomain",Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
	[string]$TypeName,
    [parameter(ParameterSetName="ServiceNameLocal",Mandatory=$true,ValueFromPipeline=$false)]
    [parameter(ParameterSetName="TypeNameLocal",Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
	[switch]$LocalIdentity,
    [parameter(ParameterSetName="ServiceNameDomain",Mandatory=$true,ValueFromPipeline=$false)]
    [parameter(ParameterSetName="TypeNameDomain",Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
	[switch]$DomainIdentity,
    [parameter(ParameterSetName="ServiceNameLocal",Mandatory=$true,ValueFromPipeline=$false)]
    [parameter(ParameterSetName="TypeNameLocal",Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateSet("LocalSystem","LocalService","NetworkService")]
	[string]$Identity,
	[parameter(ParameterSetName="ServiceNameDomain",Mandatory=$true,ValueFromPipeline=$false)]
    [parameter(ParameterSetName="TypeNameDomain",Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
	[string]$AccountName
)

# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
	Write-Host "Loading the SharePoint PowerShell snapin..."
	Add-PSSnapin Microsoft.SharePoint.PowerShell
}	

# Get the service
if ($ServiceName -eq $null)
{
    # Using the Type
    $svc = (Get-SPFarm).Services | where {$_.TypeName -eq $TypeName}
    if ($svc -eq $null)
    {
        Write-Host "The service with the type '$TypeName' doesn't exist. Halting execution!"
        break
    }
}
else
{
    # Using the Name
    $svc = (Get-SPFarm).Services | where {$_.Name -eq $ServiceName}
    if ($svc -eq $null)
    {
        Write-Host "The service with the name '$ServiceName' doesn't exist. Halting execution!"
        break
    }
}

# Get the managed account if required
if ($DomainIdentity)
{
    $managedAccount = Get-SPManagedAccount -Identity $AccountName
    if ($managedAccount -eq $null)
    {
        Write-Host "The domain account '$AccountName' is not a valid managed account. Halting execution!"
        break
    }
}

# Set the Service to run with a new identity
if ($LocalIdentity)
{
    $svc.ProcessIdentity.CurrentIdentityType = $Identity
}
else
{
    $svc.ProcessIdentity.CurrentIdentityType = "SpecificUser"
    $svc.ProcessIdentity.ManagedAccount = $managedAccount 
}
$svc.ProcessIdentity.Update()
$svc.ProcessIdentity.Deploy()