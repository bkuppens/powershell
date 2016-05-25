<#
.SYNOPSIS
	Replace old SP2007 list icons with new icons

.DESCRIPTION
	Replace old SP2007 list icons with new icons.

.NOTES
	File Name: Replace-ListImageUrl.ps1
	Author   : Bart Kuppens
	Version  : 1.0
#>

# Switch to STA mode
$host.Runspace.ThreadOptions = "ReuseThread"

cls

# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
	Write-Output "Loading SharePoint Snap-in..."
	Add-PSSnapin Microsoft.SharePoint.PowerShell
}

function Get-NewImageUrl([string]$ImageUrl)
{
    $newImageUrl = [string]::Empty
    switch ($ImageUrl.ToLower())
    {
        "/_layouts/images/itil.gif" { $newImageUrl = "/_layouts/15/images/itil.png?rev=23"; break }
        "/_layouts/images/itil.png" { $newImageUrl = "/_layouts/15/images/itil.png?rev=23"; break }
        "/_layouts/images/itdatash.gif" { $newImageUrl = "/_layouts/15/images/itdatash.png?rev=23"; break}
        "/_layouts/images/itwfh.png" { $newImageUrl = "/_layouts/15/images/itwfh.png?rev=23"; break}
        "/_layouts/images/users.gif" { $newImageUrl = "/_layouts/15/images/users.gif?rev=23"; break}
        "/_layouts/images/itdisc.gif" { $newImageUrl = "/_layouts/15/images/itdisc.png?rev=23"; break}
        "/_layouts/images/itevent.gif" { $newImageUrl = "/_layouts/15/images/itevent.png?rev=23"; break}
        "/_layouts/images/itcommnt.gif" { $newImageUrl = "/_layouts/15/images/itcommnt.gif?rev=23"; break}
        "/_layouts/images/itdl.gif" { $newImageUrl = "/_layouts/15/images/itdl.png?rev=23"; break}
        "/_layouts/images/itdl.png" { $newImageUrl = "/_layouts/15/images/itdl.png?rev=23"; break}
        "/_layouts/images/itobject.gif" { $newImageUrl = "/_layouts/15/images/itobject.png?rev=23"; break}
        "/_layouts/images/itgen.gif" { $newImageUrl = "/_layouts/15/images/itgen.png?rev=23"; break}
        "/_layouts/images/itgen.png" { $newImageUrl = "/_layouts/15/images/itgen.png?rev=23"; break}
        "/_layouts/images/itsurvey.gif" { $newImageUrl = "/_layouts/15/images/itsurvey.png?rev=23"; break}
        "/_layouts/images/icxddoc.gif" { $newImageUrl = "/_layouts/15/images/ICXDDOC.GIF?rev=23"; break}
        "/_layouts/images/ittxtbox.gif" { $newImageUrl = "/_layouts/15/images/ittxtbox.gif?rev=23"; break}
        "/_layouts/images/ittask.gif" { $newImageUrl = "/_layouts/15/images/ittask.png?rev=23"; break}
        "/_layouts/images/itfl.gif" { $newImageUrl = "/_layouts/15/images/itfl.png?rev=23"; break}
        "/_layouts/images/itcontct.gif" { $newImageUrl = "/_layouts/15/images/itcontct.png?rev=23"; break}                                                        
        "/_layouts/images/itthgbrg.gif" { $newImageUrl = "/_layouts/15/images/itthgbrg.png?rev=23"; break} 
        "/_layouts/images/itposts.gif" { $newImageUrl = "/_layouts/15/images/itposts.gif?rev=23"; break}
        "/_layouts/images/itlink.gif" { $newImageUrl = "/_layouts/15/images/itlink.png?rev=23"; break}
        "/_layouts/images/itcat.gif" { $newImageUrl = "/_layouts/15/images/itcat.gif?rev=23"; break}
        "/_layouts/images/itagnda.gif" { $newImageUrl = "/_layouts/15/images/itagnda.png?rev=23"; break}
        "/_layouts/images/itann.gif" { $newImageUrl = "/_layouts/15/images/itann.png?rev=23"; break}
    }
    return $newImageUrl
}

$sites = Get-SPSite -Limit All
foreach ($site in $sites)
{
	try
	{
		$webs = $site.AllWebs
		foreach ($web in $webs)
		{
			try
			{
                Write-Host -ForegroundColor Yellow $web.Url
                $lists = $web.Lists
                foreach ($list in $lists)
                {
                    Write-Host "   $($list.Title)"
                    $ImageUrl = Get-NewImageUrl -ImageUrl $list.ImageUrl
                    if (![String]::IsNullOrEmpty($ImageUrl))
                    {
                        Write-Host -ForegroundColor DarkGreen "      OldImage: $($list.ImageUrl) ; NewImage: $ImageUrl"
                        $list.ImageUrl = $ImageUrl
                        $list.Update()
                    }
                    else
                    {
                        Write-Host -ForegroundColor Red "      Image '$($list.ImageUrl)' not replaced"
                    }
                }
            }
            catch {}
            finally
            {
                $web.Dispose()
            }
        }
    }
    catch {}
    finally
    {
        $site.Dispose()
    }
}