<#
.SYNOPSIS
	Join a server in an existing SharePoint farm.

.DESCRIPTION
	Join a server in an existing SharePoint farm

.NOTES
	File Name: Join-Farm.ps1
	Author   : Bart Kuppens
	Version  : 2.3
	
.PARAMETER DBServer
	Specifies the name of the database server where the configuration database of the farm is located.
	
.PARAMETER DBName
	Specifies the name of the configuration database of the farm where this server needs to be joined to.
	
.PARAMETER PassPhrase
	The Farm passphrase.

.PARAMETER SPVersion
    	Specifies the version of SharePoint (2010, 2013, or 2016)

.EXAMPLE
        PS > .\Join-Farm.ps1 -DBServer SHPDB -DBName SharePoint_Config_DB -PassPhrase "blabla" -SPVersion 2016
#>

param(
	[parameter(Position=0,Mandatory=$true,ValueFromPipeline=$false)]
	[string]$DBServer,
	[parameter(Position=1,Mandatory=$true,ValueFromPipeline=$false)]
	[string]$DBName,
	[parameter(Position=2,Mandatory=$true,ValueFromPipeline=$false)]
	[string]$PassPhrase,
    [parameter(Position=5,Mandatory=$true,ValueFromPipeline=$false)]
	[ValidateSet("2010","2013","2016")]$SPVersion
)

# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell
}

$SecurePassPhrase = ConvertTo-SecureString $PassPhrase -AsPlainText -Force

# If SP2016 is targeted, ask for the serverrole for this server (default = WebFrontEnd)
if ($SPVersion -eq "2016")
{
    $choices = [System.Management.Automation.Host.ChoiceDescription[]]@("&Custom","&WebFrontEnd", "&Application", "&DistributedCache", "S&ingleServerFarm","S&earch")
    $default = 1
    $choiceValue = $host.UI.PromptForChoice("Server Role","Specify the role for this server",$choices,$default)
    switch($choiceValue)
    {
        0 { $ServerRole = "Custom" }
        1 { $ServerRole = "WebFrontEnd" }
        2 { $ServerRole = "Application" }
        3 { $ServerRole = "DistributedCache" }
        4 { $ServerRole = "SingleServerFarm" }
        5 { $ServerRole = "Search" }
    }
}

# If SP2013 or SP2016 is targeted, ask if this first server will be a DistributedCache Host or not (default = Yes)
$IsDistributedCacheHost = $false
if ($SPVersion -eq "2013" -or $SPVersion -eq "2016")
{
	$choices = [System.Management.Automation.Host.ChoiceDescription[]]@("&Yes","&No")
	$default = 0
	$choiceValue = $host.UI.PromptForChoice("Distributed Cache","Do you want this server to act as a Distributed Cache Host?",$choices,$default)
	if ($choiceValue -eq 0)
	{
		$IsDistributedCacheHost = $true
	}
	else
	{
		$IsDistributedCacheHost = $false
	}
}

try 
{
	Write-Host "Joining the farm..."
    if ($SPVersion -eq "2016")
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
		if ($SPVersion -eq "2013")
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
