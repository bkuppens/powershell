<#
.SYNOPSIS
	Sets a custom field delimiter for CSV exports in SSRS running in SharePoint Integrated Mode

.DESCRIPTION
	Sets a custom field delimiter for CSV exports in SSRS running in SharePoint Integrated Mode.

.NOTES
	File Name: Set-CSVDelimiterForSSRS.ps1
	Author   : Bart Kuppens
	Version  : 1.0

.PARAMETER Delimiter
   Specifies the custom delimiter

.EXAMPLE
   PS > .\Set-CSVDelimiterForSSRS.ps1 -Delimiter ";"
#>
[CmdletBinding()]
param(
   [parameter(Position=0,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the custom delimiter.")]
   [string]$Delimiter
)

if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
   Write-Host "Loading SharePoint cmdlets..."
   Add-PSSnapin Microsoft.SharePoint.PowerShell
}

if (Get-Command Get-SPRSServiceApplication -ErrorAction SilentlyContinue)
{
    $SSRSApp = Get-SPRSServiceApplication
    if ($SSRSApp -ne $null)
    {
        $csv = Get-SPRSExtension –identity $SSRSApp | ? {$_.Name –eq "CSV"}
        $csv.ConfigurationXml = "<DeviceInfo><FieldDelimiter>$Delimiter</FieldDelimiter></DeviceInfo>"
        $SSRSApp.Update()
    }
    else
    {
        Write-Host "The SQL Server Reporting Services application doesn't exist, halting execution."
    }
}
else
{
    Write-Host "SQL Server Reporting Services is not installed, halting execution."
}