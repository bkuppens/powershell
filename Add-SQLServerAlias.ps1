<#
.SYNOPSIS
	Adds a SQL Server alias to the current server.
	
.DESCRIPTION
	Adds a SQL Server alias to the current server.
	
.NOTES
	File Name: Add-SQLServerAlias.ps1
	Author   : Bart Kuppens
	Version  : 1.0
	
.PARAMETER Name
	Specifies the name of the alias.
		
.PARAMETER SQLServerName
	Specifies the name of the SQL Server.
		
.PARAMETER Port
	Specifies the port.
	
.EXAMPLE
	PS > Add-SQLServerAlias -Name "sp2010" -SQLServerName "sp2010" -Port 1433

	Description
	-----------
	Creates a new SQL Server alias "sp2010" for SQL Server "sp2010" on port 1433.
#>

[CmdletBinding()]
param(
	[parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Specifies the name of the alias.")]
	[string]$Name,
	[parameter(Position=1,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the name of the SQL Server.")]
	[string]$SQLServerName,
	[parameter(Position=2,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the port.")]
	[string]$Port
)	

[string]$hive = "localmachine"
[string]$Key = "SOFTWARE\\Microsoft\\MSSQLServer\\Client\\ConnectTo"

$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]$hive, $env:COMPUTERNAME)

$subkey = $reg.OpenSubKey($Key, $true)
$res = $subkey.GetValue($Name)
if (!$res)
{
	$subkey.SetValue($Name,"DBMSSOCN,$SQLServerName,$Port")
	Write-Output "Alias $Name created successfully!"
}
else
{
	Write-Output "Alias $Name already exists"
}
$reg.Close()