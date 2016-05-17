<#
.SYNOPSIS
    Retrieve a document from an unattached content database.

.DESCRIPTION
    Retrieve a document from an unattached content database.
	
.NOTES
    File Name: Get-DocFromUnattachedContentDB.ps1
    Author   : Bart Kuppens
    Version  : 1.1
	
.PARAMETER DBServer
    Specifies the database server where the content database is located.
	
.PARAMETER DBName
    Specifies the name of the content database.
	
.PARAMETER SiteURL
    Specifies the URL of the site collection where the document is located.

.PARAMETER WebURL
    Specifies the URL of the web where the document is located. Leave empty if the web is the root site of the site collection.

.PARAMETER ListTitle
    Specifies the title of the list where the document is located.

.PARAMETER DocName
    Specifies the name of the document.

.PARAMETER SaveLocation
    Specifies the location where the document needs to be saved.
	
.EXAMPLE
    PS > .\Get-DocFromUnattachedContentDB.ps1 -DBServer SHPDB -DBName "SHP_Temp_Mysite" -SiteURL "http://HDVWSVVS03:26100/personal/mysite" 
         -ListTitle "Documents" -DocName "MyDoc.pptx" -SaveLocation "c:\temp\"
#>
[CmdletBinding()]
param(
    [parameter(Position=0,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the database server where the content database is located.")]
    [string]$DBServer,
    [parameter(Position=1,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the name of the content database.")]
    [string]$DBName,
    [parameter(Position=2,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the URL of the site collection where the document is located.")]
    [string]$SiteURL,
    [parameter(Position=3,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the URL of the web where the document is located.")]
    [string]$WebURL,
    [parameter(Position=4,Mandatory=$false,ValueFromPipeline=$false,HelpMessage="Specifies the title of the list where the document is located.")]
    [string]$ListTitle,
    [parameter(Position=5,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the name of the document.")]
    [string]$DocName,
    [parameter(Position=6,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the location where the document needs to be saved.")]
    [string]$SaveLocation
)

if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
    Write-Host "Loading SharePoint cmdlets..."
    Add-PSSnapin Microsoft.SharePoint.PowerShell
}

# Connect to the unattached content database
$db = Get-SPContentDatabase -ConnectAsUnattachedDatabase -DatabaseServer $DBServer -DatabaseName $DBName

# Get a reference to the site in the DB where the document is stored
$site = Get-SPSite -ContentDatabase $db | ? {$_.Url -eq $SiteURL}
if ($site -eq $null)
{
    Write-Host -ForegroundColor Red "Site $SiteURL was not found in the database"
    break
}

# Get a reference to the web in the site where the document is stored
if ($WebURL -eq $null)
{
    # WebUrl parameter was empty. The document will be on the rootweb of the site collection.
    $web = $site.RootWeb
}
else
{
    $web = $site.AllWebs | ? {$_.Url -eq $WebURL}
    if ($web -eq $null)
    {
        Write-Host -ForegroundColor Red "Web $WebURL was not found in the database"
        break
    }
}

# Get the list where the document is stored
$list = $web.Lists[$ListTitle]
if ($list -eq $null)
{
    Write-Host -ForegroundColor Red "List $ListTitle was not found on the web $webURL"
    break
}

# Get the document from the list
$item = $list.Items | ? {$_.Name -eq $DocName}
if ($item -eq $null)
{
    Write-Host -ForegroundColor Red "A document with the name $DocName was not found in the $ListTitle list"
    break
}

# Extract the actual document and save it to disk
$binary = $item.File.OpenBinary()
$stream = New-Object System.IO.FileStream(($SaveLocation + $DocName), [System.IO.FileMode]::Create)
$writer = New-Object System.IO.BinaryWriter($stream)
$writer.Write($binary)
$writer.Close()
Write-Host -ForegroundColor DarkGreen "Document succesfully retrieved and saved under $SaveLocation$DocName"