<#
.SYNOPSIS
	Test and time Site Collection Creation for 10 sites.

.DESCRIPTION
	Test Site Collection creation using 2 possible methods:
		- Traditional site collection creation
		- New SP2016 Fast Site Creation using a site master
    For each site, the elapsed time in seconds is measured and returned.

.NOTES
	File Name: Test-SiteColCreation.ps1
	Author   : Bart Kuppens
	Version  : 1.0
	
.PARAMETER Fast
	Specifies if the Fast Site Creation method needs to be used or not.

.EXAMPLE
	PS > .\Test-SiteColCreation.ps1 -Fast $false
#>
param(
	[parameter(Position=0,Mandatory=$true,ValueFromPipeline=$false)]
	[boolean]$Fast
)

if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
    Write-Host "Loading SharePoint cmdlets..."
	Add-PSSnapin Microsoft.SharePoint.PowerShell
}

cls

if ($Fast)
{
    $SCName = "FastSite"
    Write-Host "Creating Site Collections - Fast Site Creation"
}
else
{
    $SCName = "SlowSite"
    Write-Host "Creating Site Collections - Traditional method"
}
Write-Host "----------------------------------------------"
1..10 | foreach {
    if ($Fast)
    {
        Write-Host "Creating site collection '$SCName$_'..."
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        New-SPSite "https://sp2016.westeros.local/sites/$SCName$_" -Template STS#0 -OwnerAlias "westeros\administrator" -ContentDatabase SHP_WST_Content_Portal -CreateFromSiteMaster >> $null
        $timer.Stop()
    }
    else
    {
        Write-Host -NoNewline "Creating site collection '$SCName$_'..."
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        New-SPSite "https://sp2016.westeros.local/sites/$SCName$_" -Template STS#0 -OwnerAlias "westeros\administrator" -ContentDatabase SHP_WST_Content_Portal >> $null
        $timer.Stop()
    }
    Write-Host $timer.Elapsed.TotalSeconds
}