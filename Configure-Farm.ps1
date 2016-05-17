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
    Version  : 2.2
	
.PARAMETER DatabaseServer
    The name of the server where the configuration database will be created.
	
.PARAMETER ConfigDBName
    The name of the SharePoint Configuration database.
	
.PARAMETER AdminContentDBName
    The name of the SharePoint Administration Content Database.
	
.PARAMETER CentralAdminPort
    The number of the port for the Central Administration web application
	
.PARAMETER AuthProvider
    The name of the authenticationprovider which will be used to create the
    Central Administration web application ("NTLM" or "KERBEROS")

.PARAMETER SPVersion
    Specifies the version of SharePoint (2010, 2013, or 2016)

.EXAMPLE
    PS > .\Configure-Farm.ps1 -DatabaseServer sp2010 -ConfigDBName SharePoint_Config_DB 
    -AdminContentDBName SharePoint_Administration_DB -CentralAdminPort 1111 -AuthProvider "NTLM" -SPVersion 2016
#>

param(
    [parameter(Position=0,Mandatory=$true,ValueFromPipeline=$false)]
    [string]$DatabaseServer,
    [parameter(Position=1,Mandatory=$true,ValueFromPipeline=$false)]
    [string]$ConfigDBName,
    [parameter(Position=2,Mandatory=$true,ValueFromPipeline=$false)]
    [string]$AdminContentDBName,
    [parameter(Position=3,Mandatory=$true,ValueFromPipeline=$false)]
    [int]$CentralAdminPort,
    [parameter(Position=4,Mandatory=$true,ValueFromPipeline=$false)]
    [string]$AuthProvider,
    [parameter(Position=5,Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateSet("2010","2013","2016")]$SPVersion
)

# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
    Add-PSSnapin Microsoft.SharePoint.PowerShell
}

# Get the Farm Credentials needed for the configuration
$FarmCredential = Get-Credential -Message "Enter the Farm Account credentials"
if ($FarmCredential -eq $null)
{
    Write-Host -ForegroundColor Red "No Farm Credentials supplied, halting farm configuration!"
    break
}

# Get the Passphrase for the configuration
$Passphrase = Read-Host -AsSecureString "Enter the Farm Configuration passphrase"
if ($Passphrase -eq $null)
{
    Write-Host -ForegroundColor Red "No passphrase supplied, halting farm configuration!"
    break
}

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
        2 { $ServerRole = "SingleServerFarm" }
        3 { $ServerRole = "Search" }
        4 { $ServerRole = "Application" }
        5 { $ServerRole = "DistributedCache" }
    }
}

# If SP2013 or SP2016 is targeted, ask if this first server will be a DistributedCache Host or not (default = Yes)
$IsDistributedCacheHost = $false
if ($SPVersion -eq "2013" -or $SPVersion -eq "2016")
{
    $choices = [System.Management.Automation.Host.ChoiceDescription[]]@("&Yes","&No")
    $default = 0
    $choiceValue = $host.UI.PromptForChoice("Distributed Cache","Do you want this first server to act as a Distributed Cache Host?",$choices,$default)
    if ($choiceValue -eq 0)
    {
        $IsDistributedCacheHost = $true
    }
    else
    {
        $IsDistributedCacheHost = $false
    }
}

# Start configuration
Write-Progress -Activity "SharePoint Farm Configuration" -Status "Creating SharePoint configuration database" -PercentComplete 20
if ($SPVersion -eq "2016")
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
    if ($SPVersion -eq "2013")
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