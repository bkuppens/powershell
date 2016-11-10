<#
.SYNOPSIS
	Join a server in an existing SharePoint farm.

.DESCRIPTION
	Join a server in an existing SharePoint farm

.NOTES
	File Name: Join-Farm.ps1
	Author   : Bart Kuppens - CTG Belgium
	Version  : 2.5
	
.PARAMETER DBServer
	Specifies the name of the database server where the configuration database of the farm is located.
	
.PARAMETER DBName
	Specifies the name of the configuration database of the farm where this server needs to be joined to.
	
.PARAMETER PassPhrase
	The Farm passphrase.

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
    PS > .\Join-Farm.ps1 -DBServer SHPDB -DBName SharePoint_Config_DB -PassPhrase "blabla" -SP2010

    DESCRIPTION
    -----------
    Will create a new SharePoint 2010 farm.

.EXAMPLE
    PS > .\Join-Farm.ps1 -DBServer SHPDB -DBName SharePoint_Config_DB -PassPhrase "blabla" -SP2013

    DESCRIPTION
    -----------
    Will create a new SharePoint 2013 farm but will not configure the current server as a DistributedCache Host

.EXAMPLE
    PS > .\Join-Farm.ps1 -DBServer SHPDB -DBName SharePoint_Config_DB -PassPhrase "blabla" -SP2016 -ServerRole Search

    DESCRIPTION
    -----------
    Will create a new SharePoint 2016 farm and give it a "Search" server role.

#>
[CmdletBinding()]
param(
    [parameter(ParameterSetName="2010",Mandatory=$true,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2013",Mandatory=$true,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2016",Mandatory=$true,ValueFromPipeLine=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$DBServer,
    [parameter(ParameterSetName="2010",Mandatory=$true,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2013",Mandatory=$true,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2016",Mandatory=$true,ValueFromPipeLine=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$DBName,
    [parameter(ParameterSetName="2010",Mandatory=$true,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2013",Mandatory=$true,ValueFromPipeLine=$false)]
    [parameter(ParameterSetName="2016",Mandatory=$true,ValueFromPipeLine=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$PassPhrase,
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

$SecurePassPhrase = ConvertTo-SecureString $PassPhrase -AsPlainText -Force

try 
{
    Write-Host "Joining the farm..."
    if ($SP2016)
    {
        if ($IsDistributedCacheHost)
        {
            Connect-SPConfigurationDatabase -DatabaseServer $DBServer -DatabaseName $DBName -PassPhrase $SecurePassPhrase -LocalServerRole $ServerRole
        }
        else
        {
            Connect-SPConfigurationDatabase -DatabaseServer $DBServer -DatabaseName $DBName -PassPhrase $SecurePassPhrase -LocalServerRole $ServerRole -SkipRegisterAsDistributedCacheHost
        }
    }
    else
    {
        if ($SP2013)
        {
            if ($IsDistributedCacheHost)
            {
                Connect-SPConfigurationDatabase -DatabaseServer $DBServer -DatabaseName $DBName -PassPhrase $SecurePassPhrase
            }
            else
            {
                Connect-SPConfigurationDatabase -DatabaseServer $DBServer -DatabaseName $DBName -PassPhrase $SecurePassPhrase -SkipRegisterAsDistributedCacheHost
            }
        }
        else
        {
            Connect-SPConfigurationDatabase -DatabaseServer $DBServer -DatabaseName $DBName -PassPhrase $SecurePassPhrase
        }
    }

    Write-Host "Installing Help"
    Install-SPHelpCollection -All

    Write-Host "Securing SharePoint resources"
    Initialize-SPResourceSecurity

    Write-Host "Installing services"
    Install-SPService

    Write-Host "Installing features"
    Install-SPFeature -AllExistingFeatures

    Write-Host "Installing application content"
    Install-SPApplicationContent

    # Start Services if needed
    Write-Host "Checking status SharePoint Timer service"
    $timersvc = Get-Service SPTimerV4
    if ($timersvc.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running)
    {
        Write-Host "   SharePoint Timer Service not running... starting the service"
        $timersvc.Start()
    }

    if (($SPVersion -eq "2013" -or $SPVersion -eq "2016") -and ($IsDistributedCacheHost))
    {
        Write-Host "Checking status Distributed Cache Service"
        $distributedCacheSvc = Get-Service AppFabricCachingService
        if ($distributedCacheSvc.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running)
        {
            Write-Host "   AppFabric Caching Service not running... starting the service"
            $distributedCacheSvc.Start()
        }
    }
} 
catch 
{
    Write-Host "Server was not joined in the farm"
}
