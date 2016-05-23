<#
.SYNOPSIS
	Replace eventreceivers with an updated assembly signature

.DESCRIPTION
	Replace eventreceivers with an updated assembly signature.

.NOTES
	File Name: Replace-EventReceiver.ps1
	Author   : Bart Kuppens
	Version  : 1.0
	
.PARAMETER CSVFile
	Specifies the path and name of the CSV file with the eventreceivers. This CSV can be created from the output of the
    Get-EventReceiver.ps1 script.
    Layout:
        "Web";"List";"ID";"Assembly";"Class";"Type";"Name";"SequenceNumber";"Synchronization"
    Where:
        - Web             : Url of the Web
        - List            : Title of the List
        - ID              : ID of the eventreceiver
        - Class           : Class of the eventreceiver
        - Type            : Type of the eventreceiver
        - Name            : Name of the eventreceiver
        - SequenceNumber  : SequenceNumber of the eventreceiver
        - Synchronization : Synchronization of the eventreceiver 
	
.PARAMETER Delimiter
    Specifies the delimiter used in the CSV file.

.PARAMETER NewSignature
	Specifies the new assembly signature.

.EXAMPLE
    PS > .\Replace-EventReceiver.ps1 -CSVFile "c:\temp\eventreceivers.csv" -Delimiter ";" 
              -NewSignature "westeros.sharepoint, Version=1.0.0.0, Culture=neutral, PublicKeyToken=d944c1e5ac03aeaa" 
		
#>
param(
	[parameter(Position=0,Mandatory=$true,ValueFromPipeline=$false)]
	[string]$CSVFile,
	[parameter(Position=1,Mandatory=$true,ValueFromPipeline=$false)]
	[string]$Delimiter,
	[parameter(Position=2,Mandatory=$true,ValueFromPipeline=$false)]
	[string]$NewSignature
)

# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell
}

# Check if file exists
if (!(Test-Path $CSVFile))
{
    Write-Host "File $CSVFile does not exist, halting execution!"
    break
}
$CSVData = Import-Csv $CSVFile -Delimiter $Delimiter

foreach ($CSVRow in $CSVData)
{
    $web = Get-SPWeb $CSVRow.Web
    if ($web -ne $null)
    {
        $list = $web.Lists[$CSVRow.List]
        if ($list -ne $null)
        {
            $list.EventReceivers[[Guid]$CSVRow.ID].Delete()
            $ev = $list.EventReceivers.Add()
            $ev.Assembly = $NewSignature
            $ev.Class = $CSVRow.Class
            $ev.Type = $CSVRow.Type
            $ev.Name = $CSVRow.Name
            $ev.SequenceNumber = $CSVRow.SequenceNumber
            $ev.Synchronization = $CSVRow.Synchronization
            $ev.Update()
        }
        else
        {
            Write-Host "List '$($CSVRow.List)' not found on $($CSVRow.Web)"
        }
        $web.Dispose()
    }
    else
    {
        Write-Host "Web with URL $($CSVRow.Web) not found."
    }
}

