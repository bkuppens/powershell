<#
.SYNOPSIS
	Get eventreceivers with a specific assembly signature

.DESCRIPTION
	Get eventreceivers with a specific assembly signature.

.NOTES
	File Name: Get-EventReceiver.ps1
	Author   : Bart Kuppens
	Version  : 1.0
	
.PARAMETER Signature
	Specifies the assembly signature of the eventreceivers to be returned.
	
.EXAMPLE
    PS > .\Get-EventReceiver.ps1 -Signature "westeros.sharepoint, Version=1.0.0.0, Culture=neutral, PublicKeyToken=d944c1e5ac03aeaa" 
                  | Export-CSV -Path "c:\temp\eventreceivers.csv" -Delimiter ";" -NoTypeInformation
	
#>
param(
	[parameter(Position=0,Mandatory=$true,ValueFromPipeline=$false)]
	[string]$Signature
)

# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell
}

$sites = Get-SPSite -limit All
foreach ($site in $sites)
{
    $webs = $site.AllWebs
    foreach ($web in $webs)
    {
        $lists = $web.Lists | ? {$_.EventReceivers.Count -gt 0}
        foreach ($list in $lists)
        {
            foreach ($eventreceiver in $list.EventReceivers)
            {
                if ($eventreceiver.Assembly -eq $Signature)
                {
                    $receiver = [ordered]@{
                        "Web" = $web.Url
                        "List" = $list.Title
                        "ID" = $eventreceiver.Id
                        "Assembly" = $eventreceiver.Assembly
                        "Class" = $eventreceiver.Class
                        "Type" = $eventreceiver.Type
                        "Name" = $eventreceiver.Name
                        "SequenceNumber" = $eventreceiver.SequenceNumber
                        "Synchronization" = $eventreceiver.Synchronization
                    }
                    New-Object PSObject -Property $receiver
                }
            }
        }
        $web.Dispose()
    }
    $site.Dispose()
}


