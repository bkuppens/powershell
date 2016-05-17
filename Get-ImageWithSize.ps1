<#
.SYNOPSIS
   Returns a list of images for a specific webapplication which are larger than a specified size.
	
.DESCRIPTION
   Returns a list of images for a specific webapplication which are larger than a specified size.
	
.NOTES
   File Name: Get-ImageWithSize.ps1
   Version  : 1.0
	
.PARAMETER WebApplication
   Specifies the URL of the Web Application.
    
.PARAMETER MaxSize
   Specifies the size in KB which images must minimum have to be returned.
	
.EXAMPLE
   PS > .\Get-ImageWithSize.ps1 -WebApplication http://intranet.westeros.local -MaxSize 512 | Out-GridView

   Description
   -----------
   Returns a list of images found on intranet.westeros.local which are larger then 512KB.
#>
[CmdletBinding()]
param(
   [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the URL of the Web Application.")] 
   [string]$WebApplication,
   [Parameter(Position=1,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the size which images must minimum have to be returned.")] 
   [string]$MaxSize
)

# Check if a passed docIcon is a known image format
function IsImage([string]$docIcon)
{
   return $ImageFormats.Contains($docIcon.ToLower())
}

# List with Image formats (add types if needed)
[string]$ImageFormats = "png;jpg;gif;bmp"

# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
   Write-Host "Loading the SharePoint PowerShell snapin..."
   Add-PSSnapin Microsoft.SharePoint.PowerShell
}	
	
$SPWebApp = Get-SPWebApplication $WebApplication -EA SilentlyContinue
if ($SPWebApp -eq $null)
{
   Write-Error "$WebApplication is not a valid SharePoint Web application."
}
else
{
   Write-Host -ForegroundColor Green "Please wait... gathering data."
   $sites = $SPWebApp.Sites
   foreach ($site in $sites)
   {
      try
      {
         $webs = $site.AllWebs
         foreach ($web in $webs)
         {
            try
            {
               $lists = $web.GetListsOfType("DocumentLibrary") | ? {$_.IsCatalog -eq $false}
               foreach ($list in $lists)
               {
                  $items = $list.Items
                  foreach ($item in $items)
                  {
                     [xml]$ItemData = $item.Xml
                     if (IsImage -docIcon $ItemData.row.ows_DocIcon)
                     {
                        $imgSize = $item.File.Length/1KB
                        if ($imgSize -gt $maxSize)
                        {
                           $AuthorData = $item["Created By"].ToString().Split(";#")
                           $data = @{
                              "Web Application" = $SPWebApp.Name.ToString()
                              "Site" = $site.Url
                              "Web" = $web.Url
                              "List" = $list.Title
                              "Item ID" = $item.ID
                              "Item URL" = $item.Url
                              "Item Title" = $item.Title
                              "Item Created" = $item["Created"]
                              "Item Modified" = $item["Modified"]
                              "Created By" = $AuthorData[2]
                              "File size" = $item.File.Length/1KB
                           }
                           New-Object PSOBject -Property $data
                        }
                     }
                  }
               }
            }
            catch {}
            finally { $web.Dispose() }		
         }
      }
      catch {}
      finally { $site.Dispose() }
   }
}