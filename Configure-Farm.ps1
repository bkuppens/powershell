<#
.SYNOPSIS
	SharePoint Farm Configuration.

.DESCRIPTION
	Configures the local SharePoint farm:
		- Create the configuration database
		- Secure SharePoint resources
		- Install Services
		- Install Features
		- Provision Central Administration
		- Install Help Collection
		- Install Application Content

.NOTES
	File Name: Configure-Farm.ps1
	Author   : Bart Kuppens
	Version  : 2.5
	
.PARAMETER DatabaseServer
	Specifies the name of the server where the configuration database will be created.
	
.PARAMETER ConfigDBName
	Specifies the name of the SharePoint Configuration database.
	
.PARAMETER AdminContentDBName
	Specifies the name of the SharePoint Administration Content Database.
	
.PARAMETER CentralAdminPort
	Specifies the number of the port for the Central Administration web application
	
.PARAMETER AuthProvider
	Specifies the name of the authenticationprovider which will be used to create the
	Central Administration web application ("NTLM" or "KERBEROS")

.PARAMETER FarmCredential
    Specifies the "domain\username" to be used as the Farm account. If omitted, you will be prompted to 
    provide a valid domain account."

.PARAMETER SP2010
    Specified when a new farm is created for SharePoint 2010.

.PARAMETER SP2013
    Specified when a new farm is created for SharePoint 2013.

.PARAMETER SP2016
    Specified when a new farm is created for SharePoint 2016.

.PARAMETER IsDistributedCacheHost
    Specified when this server will be a Distributed Cache Host.
    For SP2016 farms, this parameter is only important when a "Custom" ServerRole is required and this local server needs to be
    a DistributedCache server.

.PARAMETER ServerRole
    Specifies the role of the first server in the new farm.
    Possible values: Custom, WebFrontEnd, Application, DistributedCache, SingleServerFarm, Search, 
                     ApplicationWithSearch, WebFrontEndWithDistributedCache
    
    IMPORTANT!!! The roles 'ApplicationWithSearch' and 'WebFrontEndWithDistributionCache' are only valid 
                 when Feature Pack 1 has been installed (KB3127940 & KB3127942)

.EXAMPLE
	PS > .\Configure-Farm.ps1 -DatabaseServer SHPDB -ConfigDBName SharePoint_Config_DB 
	-AdminContentDBName SharePoint_Administration_DB -CentralAdminPort 1111 -AuthProvider NTLM -SP2010

    DESCRIPTION
    -----------
    Will create a new SharePoint 2010 farm.

.EXAMPLE
	PS > .\Configure-Farm.ps1 -DatabaseServer SHPDB -ConfigDBName SharePoint_Config_DB 
	-AdminContentDBName SharePoint_Administration_DB -CentralAdminPort 1111 -AuthProvider NTLM -SP2013 -IsDistributedCacheHost

    DESCRIPTION
    -----------
    Will create a new SharePoint 2013 farm and set the local server as a distributed cache host.

.EXAMPLE
	PS > .\Configure-Farm.ps1 -DatabaseServer SHPDB -ConfigDBName SharePoint_Config_DB 
	-AdminContentDBName SharePoint_Administration_DB -CentralAdminPort 1111 -AuthProvider NTLM -SP2016 -ServerRole Application

    DESCRIPTION
    -----------
    Will create a new SharePoint 2016 farm and give the local server the "Application" server minrole.

.EXAMPLE
	PS > .\Configure-Farm.ps1 -DatabaseServer SHPDB -ConfigDBName SharePoint_Config_DB 
	-AdminContentDBName SharePoint_Administration_DB -CentralAdminPort 1111 -AuthProvider NTLM -SP2016 -ServerRole DistributedCache

    DESCRIPTION
    -----------
    Will create a new SharePoint 2016 farm and give the local server the "DistributedCache" server minrole.

#>
[CmdletBinding()]
param(
    [parameter(ParameterSetName="2010",Mandatory=$true,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2013",Mandatory=$true,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2016",Mandatory=$true,ValueFromPipeLine=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$DatabaseServer,
    [parameter(ParameterSetName="2010",Mandatory=$true,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2013",Mandatory=$true,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2016",Mandatory=$true,ValueFromPipeLine=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$ConfigDBName,
    [parameter(ParameterSetName="2010",Mandatory=$true,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2013",Mandatory=$true,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2016",Mandatory=$true,ValueFromPipeLine=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$AdminContentDBName,
    [parameter(ParameterSetName="2010",Mandatory=$true,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2013",Mandatory=$true,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2016",Mandatory=$true,ValueFromPipeLine=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$CentralAdminPort,
    [parameter(ParameterSetName="2010",Mandatory=$true,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2013",Mandatory=$true,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2016",Mandatory=$true,ValueFromPipeLine=$false)]
    [ValidateSet("NTLM","Kerberos")]
    [string]$AuthProvider,
    [parameter(ParameterSetName="2010",Mandatory=$false,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2013",Mandatory=$false,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2016",Mandatory=$false,ValueFromPipeLine=$false)]
    [PSCredential]$FarmCredential,
    [parameter(ParameterSetName="2010",Mandatory=$true,ValueFromPipeLine=$false)]
    [switch]$SP2010,
    [parameter(ParameterSetName="2013",Mandatory=$true,ValueFromPipeLine=$false)]
    [switch]$SP2013,
    [parameter(ParameterSetName="2016",Mandatory=$true,ValueFromPipeLine=$false)]
    [switch]$SP2016,
    [parameter(ParameterSetName="2013",Mandatory=$false,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2016",Mandatory=$false,ValueFromPipeLine=$false)]
    [switch]$IsDistributedCacheHost,
    [parameter(ParameterSetName="2016",Mandatory=$true,ValueFromPipeLine=$false)]
    [ValidateSet("Custom","WebFrontEnd","Application","DistributedCache","SingleServerFarm","Search","ApplicationWithSearch","WebFrontEndWithDistributedCache")]
    [string]$ServerRole
)

# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell
}

# Get the Farm Credentials needed for the configuration
if ($FarmCredential -eq $null)
{
    $FarmCredential = Get-Credential -Message "Enter the Farm Account credentials"
    if ($FarmCredential -eq $null)
    {
	    Write-Host -ForegroundColor Red "No Farm Credentials supplied, halting farm configuration!"
	    break
    }
}

# Get the Passphrase for the configuration
$Passphrase = Read-Host -AsSecureString "Enter the Farm Configuration passphrase"
if ($Passphrase -eq $null)
{
    Write-Host -ForegroundColor Red "No passphrase supplied, halting farm configuration!"
	break
}

# Start configuration
Write-Progress -Activity "SharePoint Farm Configuration" -Status "Creating SharePoint configuration database" -PercentComplete 20
if ($SP2016)
{
	if ($IsDistributedCacheHost)
	{
        New-SPConfigurationDatabase -DatabaseName $ConfigDBName -DatabaseServer $DatabaseServer -AdministrationContentDatabaseName $AdminContentDBName -FarmCredentials $FarmCredential -Passphrase $Passphrase -LocalServerRole $ServerRole -ErrorVariable err
	}
	else
	{
		New-SPConfigurationDatabase -DatabaseName $ConfigDBName -DatabaseServer $DatabaseServer -AdministrationContentDatabaseName $AdminContentDBName -FarmCredentials $FarmCredential -Passphrase $Passphrase -LocalServerRole $ServerRole -SkipRegisterAsDistributedCacheHost -ErrorVariable err
	}
}
else
{
	if ($SP2013)
	{
		if ($IsDistributedCacheHost)
		{
			New-SPConfigurationDatabase -DatabaseName $ConfigDBName -DatabaseServer $DatabaseServer -AdministrationContentDatabaseName $AdminContentDBName -FarmCredentials $FarmCredential -Passphrase $Passphrase -ErrorVariable err
		}
		else
		{
			New-SPConfigurationDatabase -DatabaseName $ConfigDBName -DatabaseServer $DatabaseServer -AdministrationContentDatabaseName $AdminContentDBName -FarmCredentials $FarmCredential -Passphrase $Passphrase -SkipRegisterAsDistributedCacheHost -ErrorVariable err
		}
	}
	else
	{
		New-SPConfigurationDatabase -DatabaseName $ConfigDBName -DatabaseServer $DatabaseServer -AdministrationContentDatabaseName $AdminContentDBName -FarmCredentials $FarmCredential -Passphrase $Passphrase -ErrorVariable err
	}
}
Write-Progress -Activity "SharePoint Farm Configuration" -Status "Verifying farm creation" -PercentComplete 30
$spfarm = Get-SPFarm

if ($spfarm -ne $null) 
{   
	Write-Progress -Activity "SharePoint Farm Configuration" -Status "Securing SharePoint resources" -PercentComplete 40
	Initialize-SPResourceSecurity -ErrorVariable err            
        
	Write-Progress -Activity "SharePoint Farm Configuration" -Status "Installing services" -PercentComplete 50    
	Install-SPService -ErrorVariable err
        
	Write-Progress -Activity "SharePoint Farm Configuration" -Status "Installing features" -PercentComplete 60    
	Install-SPFeature -AllExistingFeatures -ErrorVariable err > $null
        
	Write-Progress -Activity "SharePoint Farm Configuration" -Status "Provisioning Central Administration" -PercentComplete 70    
	New-SPCentralAdministration -Port $CentralAdminPort -WindowsAuthProvider $AuthProvider -ErrorVariable err
        
	Write-Progress -Activity "SharePoint Farm Configuration" -Status "Installing Help" -PercentComplete 80      
	Install-SPHelpCollection -All -ErrorVariable err
        
	Write-Progress -Activity "SharePoint Farm Configuration" -Status "Installing application content" -PercentComplete 90      
	Install-SPApplicationContent -ErrorVariable err
} 
else 
{ 
	Write-Error "ERROR: $err"
}                  
