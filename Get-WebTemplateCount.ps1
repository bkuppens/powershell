<#
.SYNOPSIS
    Retrieves all used web templates and the usage count for each

.DESCRIPTION
    Retrieves all used web templates and the usage count for each

.NOTES
    File Name: Get-WebTemplateCount.ps1
    Author   : Bart Kuppens
    Version  : 1.0
	
.EXAMPLE
    PS > .\Get-WebTemplateCount.ps1
#>

# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
    Write-Output "Loading SharePoint Snap-in..."
    Add-PSSnapin Microsoft.SharePoint.PowerShell
}

# Switch to STA mode
$host.Runspace.ThreadOptions = "ReuseThread"

$list = @{}
$Sites = Get-SPSite -Limit All
foreach ($site in $Sites)
{
    try
    {
        $webs = $site.AllWebs
        foreach ($web in $webs)
        {
            try
            {
                $WebTemplate = $web.WebTemplate
                $ConfigID = $web.Configuration
                $item = "$WebTemplate#$ConfigID"
                $list[$item]++
            }
            catch
            {
                Write-Host "Error enumerating site '$($web.Url)'"
            }
            finally { $web.Dispose() }
        }
    }
    catch { }
    finally { $site.Dispose() }
}

$list.GetEnumerator() | % {
    $template = @{
        "Name" = $_.Name
        "Title" = Get-SPWebTemplate $_.Name | Select -expand Title
        "Count" = $_.Value
    }
    New-Object PSObject -Property $template
}