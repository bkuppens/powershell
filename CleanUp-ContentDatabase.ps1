<#
.SYNOPSIS
	Cleanup site collection marked for deletion and perform a shrink

.DESCRIPTION
	Cleanup site collection marked for deletion and perform a shrink.

.NOTES
	File Name: CleanUp-ContentDatabase.ps1
	Author   : Bart Kuppens
	Version  : 1.0
	
.PARAMETER WebApplication
	Specifies the URL of the webapplication where the cleanup has to be executed.
	
.PARAMETER ContentDatabase
	Specifies the name of the content database which has to be cleaned.
	
.EXAMPLE
	PS C:\> .\Cleanup-ContentDatabase.ps1 -WebApplication http://teamsites.westeros.local ContentDatabase "SHP_WST_Content_TeamSites"
#>
[CmdletBinding()]
param(
	[parameter(Position=0,Mandatory=$true,ValueFromPipeline=$false)]
	[string]$WebApplication,
	[parameter(Position=1,Mandatory=$true,ValueFromPipeline=$false)]
	[string]$ContentDatabase
)
cls
# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
	Write-Output "Loading SharePoint Snap-in..."
	Add-PSSnapin Microsoft.SharePoint.PowerShell
}

# Check if the webapplication exists
$webapp = Get-SPWebApplication $WebApplication -ErrorAction SilentlyContinue
if ($webapp -eq $null)
{
    Write-Host -ForegroundColor Red "Web application '$WebApplication' doesn't exist, halting execution!"
    break
}

# Check if the contentdatabase exists
$contentdb = Get-SPContentDatabase -Identity $ContentDatabase -ErrorAction SilentlyContinue
if ($contentdb -eq $null)
{
    Write-Host -ForegroundColor Red "Content database '$ContentDatabase' doesn't exist, halting execution!"
    break
}
else
{
    # Check if the content database is attached to the web application
    if ($contentdb.WebApplication -ne $webapp)
    {
        Write-Host -ForegroundColor Red "Content database '$ContentDatabase' is not attached to '$WebApplication', halting execution!"
        break
    }
}

# Start the Gradual Site Delete for the specified web application
$start = (Get-Date).ToUniversalTime()
$timerjob = Get-SPTimerJob -Identity "job-site-deletion" -WebApplication $webapp
Write-Host "Starting 'Gradual Site Delete' for $webApplication..."
Start-SPTimerJob -Identity $timerjob

# Wait for the job to complete
Write-Host -NoNewLine "Waiting for job completion on database $ContentDatabase..."
$jobhistoryentries = $timerjob.HistoryEntries | ? {$_.DatabaseName -eq $ContentDatabase -and $_.EndTime -gt $start}
while ($jobhistoryentries -eq $null)
{
    Start-Sleep -Seconds 300
    $jobhistoryentries = $timerjob.HistoryEntries | ? {$_.DatabaseName -eq $ContentDatabase -and $_.EndTime -gt $start}
    $status = $jobhistoryentries.Status
}
Write-Host " Completed with status : $status"
$jobhistoryentries

if ($status -eq [Microsoft.SharePoint.Administration.SPRunningJobStatus]::Succeeded)
{
    Write-Host "Continuing with database Shrink..."
    [system.Reflection.Assembly]::LoadWithPartialName("Microsoft.SQLServer.Smo") >> $null
    $server = New-Object Microsoft.SqlServer.Management.Smo.Server $contentdb.Server
    $db = $server.Databases[$ContentDatabase]
    Write-Host "Current size (Mb) : $($db.Size)"
    Write-Host "Shrinking Step 1/2..."
    $db.Shrink(5,[Microsoft.SqlServer.Management.Smo.ShrinkMethod]::NoTruncate)
    $db.Refresh()
    Write-Host "Shrinking Step 2/2..."
    $db.Shrink(5,[Microsoft.SqlServer.Management.Smo.ShrinkMethod]::TruncateOnly)
    Write-Host "New size (Mb)     : $($db.Size)"
}
else
{
    Write-Host "The timer job failed. Halting execution!"
    break
}

