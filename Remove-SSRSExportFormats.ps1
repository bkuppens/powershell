<#
.SYNOPSIS
	Removes export formats from SSRS running in SharePoint Integrated Mode

.DESCRIPTION
	Removes export formats from SSRS running in SharePoint Integrated Mode.

.NOTES
	File Name: Remove-SSRSExportFormats.ps1
	Author   : Bart Kuppens
	Version  : 1.0

.PARAMETER Formats
   Specifies the formats to be removed, separated by a semicolon.

.EXAMPLE
   PS > .\Remove-SSRSExportFormats.ps1 -Formats "TIFF;MHTML"
#>
[CmdletBinding()]
param(
   [parameter(Position=0,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the formats to be removed, separated by a semicolon.")]
   [string]$Formats
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
        $Formats.Split(';') | % {
            Set-SPRSExtension -identity $SSRSApp -ExtensionType "Render" -name $($_.ToUpper()) -ExtensionAttributes "<Visible>False</Visible>"
        }
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