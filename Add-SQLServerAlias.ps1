<#
.SYNOPSIS
    Adds a SQL Server alias to a server.  Defaults to local machine if not provided.
	
.DESCRIPTION
    Adds a SQL Server alias to a server.  Defaults to local machine if not provided.
	
.NOTES
    File Name: Add-SQLServerAlias.ps1
    Author   : Bart Kuppens
    Updates  : BillRob
    Version  : 3.0
	
.PARAMETER Name
    Specifies the name of the alias.
		
.PARAMETER SQLServerName
    Specifies the name of the SQL Server.
		
.PARAMETER Port
    Specifies the port.

.PARAMETER Machine
    Specifies the computer where the registry is located.

.PARAMETER x64
    Specifies whether the alias should be created for 64 bit.

.PARAMETER overrideIfExists
    Specifies whether, if exist, the value will be overridden.
	
.EXAMPLE
    PS > Add-SQLServerAlias -Name "SHPDB" -SQLServerName "SRV-CTG-SQL01" -Port 1433 -Machine SRV-CTG-SHP01 -x64
#>

[CmdletBinding()]
param(
    [parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Specifies the name of the alias.")]
    [string]$Name,
    [parameter(Position=1,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the name of the SQL Server.")]
    [string]$SQLServerName,
    [parameter(Position=2,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the port.")]
    [string]$Port,
    [parameter(Position=3,Mandatory=$false,ValueFromPipeline=$false,HelpMessage="Specifies the computer where the registry is located.")]
    [string]$Machine,
    [parameter(Position=4,Mandatory=$false,ValueFromPipeline=$false,HelpMessage="Specifies whether the alias should be created for 64 bit.")]
    [switch]$x64,
    [parameter(Position=5,Mandatory=$false,ValueFromPipeline=$false,HelpMessage="Specifies whether, if exist, the value will be overridden.")]
    [switch]$overrideIfExists
)

$parentKeyx86 = "SOFTWARE\\Microsoft\\MSSQLServer\\Client\\"
$parentKeyx64 = "SOFTWARE\\Wow6432Node\\Microsoft\\MSSQLServer\\Client\\"

$hive = "localmachine"
if($x64.IsPresent)
{
    $parentKey = $parentKeyx64
}
else
{
    $parentKey = $parentKeyx86
}

$key = "ConnectTo"

# If the $Machine parameter was not provided, use the local machine.
if ($Machine -eq $null)
{
    $Machine = $ENV:COMPUTERNAME
}

try
{
    # Connect to the registry (also works for remote machines)
    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]$hive, $machine)
}
catch
{
    Write-Host "Unable to connect to the registry of machine '$machine'. Please verify that the remote registry service is running and that you have administrative access to that machine."
    break
}

# Open the key in the registry
$subkey = $reg.OpenSubKey($parentKey + $key, $true)
if ($subkey -eq $null)
{
    # The key doesn't exist, open the parent key and create the subkey.
    $parentTemp = $reg.OpenSubKey($parentKey,$true)
    if ($parentTemp -eq $null)
    {
        Write-Host "Parent key not found in the registry of '$machine'. Please verify that the SQL Client Tools are installed."
        break
    }
    else
    {
        try
        {
            $parentTemp.CreateSubKey($key) >> $null
        }
        catch
        {
            Write-Host "Unable to create the key '$key' in '$parentKey' on machine '$machine'. Do you have administrative permissions?"
            break
        }
        $subkey = $reg.OpenSubKey($parentKey + $key, $true)
    }
}

$res = $subkey.GetValue($Name)
if (!$res -or $overrideIfExists.IsPresent)
{
    $subkey.SetValue($Name,"DBMSSOCN,$SQLServerName,$Port")
    if (!$res)
    {
        Write-Output "Alias '$Name' created successfully!"
    }
    else
    {
        Write-Output "Alias '$Name' updated successfully!"
    }
    
}
else
{
    Write-Output "Alias '$Name' already exists, consider using overrideIfExists parameter"
}
$reg.Close()
