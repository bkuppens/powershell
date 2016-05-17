<#
.SYNOPSIS
    Enables and configures the SharePoint BLOB Cache. 

.DESCRIPTION
    Enables and configures the SharePoint BLOB Cache. 

.NOTES
    File Name: Enable-BlobCache.ps1
    Author   : Bart Kuppens
    Version  : 2.0

.PARAMETER Url
    Specifies the URL of the Web Application for which the BLOB cache should be enabled. 

.PARAMETER Location
    Specifies the location of the BLOB Cache. 	 

.EXAMPLE
    PS > .\Enable-BlobCache.ps1 -Url http://intranet.westeros.local -Location d:\BlobCache\Intranet

   Description
   -----------
   This script enables the BLOB cache for the http://intranet.westeros.local web application and stores
   it under d:\blobcache\intranet
#>
param( 
   [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)] 
   [string]$Url,
   [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=1)] 
   [string]$Location
) 

# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
   Add-PSSnapin Microsoft.SharePoint.PowerShell
}

$webApp = Get-SPWebApplication $Url
$modifications = $webApp.WebConfigModifications | ? { $_.Owner -eq "BlobCacheMod" }
if ($modifications.Count -ne $null -and $modifications.Count -gt 0)
{
   Write-Host -ForegroundColor Yellow "Modifications have already been added!"
   break
}

# Enable Blob cache
[Microsoft.SharePoint.Administration.SPWebConfigModification] $config1 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification 
$config1.Path = "configuration/SharePoint/BlobCache" 
$config1.Name = "enabled"
$config1.Value = "true"
$config1.Sequence = 0
$config1.Owner = "BlobCacheMod" 
$config1.Type = 1 

# add max-age attribute
[Microsoft.SharePoint.Administration.SPWebConfigModification] $config2 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification 
$config2.Path = "configuration/SharePoint/BlobCache" 
$config2.Name = "max-age"
$config2.Value = "86400"
$config2.Sequence = 0
$config2.Owner = "BlobCacheMod" 
$config2.Type = 1 

# Set the location
[Microsoft.SharePoint.Administration.SPWebConfigModification] $config3 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification 
$config3.Path = "configuration/SharePoint/BlobCache" 
$config3.Name = "location"
$config3.Value = $Location
$config3.Sequence = 0
$config3.Owner = "BlobCacheMod" 
$config3.Type = 1

#Add mods to webapp and apply to web.config
$webApp.WebConfigModifications.Add($config1)
$webApp.WebConfigModifications.Add($config2)
$webApp.WebConfigModifications.Add($config3)
$webApp.Update()
$webApp.Parent.ApplyWebConfigModifications()