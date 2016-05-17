<#
.SYNOPSIS
   Returns a list of pages for a specific webapplication which contain CEWP's with script.
	
.DESCRIPTION
   Returns a list of pages for a specific webapplication which contain CEWP's with script.
	
.NOTES
   File Name: Get-CEWPWithScript.ps1
   Author   : Bart Kuppens
   Version  : 1.0
	
.PARAMETER WebApplication
   Specifies the URL of the Web Application.
	
.EXAMPLE
   PS > .\Get-CEWPWithScript.ps1 -WebApplication http://intranet.westeros.local

   Description
   -----------
   Returns all Content Editor Web Parts which contains Javascript on the http://intranet.westeros.local webapplication
#>
[CmdletBinding()]
param(
   [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the URL of the Web Application.")] 
   [string]$WebApplication
)

function Get-CEWP([string]$url)
{
   $manager = $web.GetLimitedWebPartManager($url, [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)
   $webParts = $manager.WebParts
   if ($webParts.Count -ne 0)
   {
      foreach ($webPart in $webParts)
      {
         if ($webPart.GetType() -eq [Microsoft.SharePoint.WebPartPages.ContentEditorWebPart])
         {
            if ($webPart.ContentLink.Length -gt 0)
            {
               # Check file in ContentLink for script tags
               $file = $web.GetFile($webPart.ContentLink)
               $data = $file.OpenBinary()
               $encode = New-Object System.Text.ASCIIEncoding
               $contents = $encode.GetString($data)
               if ($contents.ToLower().Contains("<script>"))
               {
                   Write-Output "$($web.Url)/$url (CONTENTLINK)"
               }
               break
            }

            if ($webPart.Content.InnerText.Contains("<script>"))
            {
               Write-Output "$($web.Url)/$url (HTML)"
            }
         }
      }
   }
}

# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
   Write-Host "Loading the SharePoint PowerShell snapin..."
   Add-PSSnapin Microsoft.SharePoint.PowerShell
}	
	
$SPWebApp = Get-SPWebApplication $WebApplication -EA SilentlyContinue
if ($SPWebApp -eq $null)
{
   Write-Error "$WebApplication is not a valid SharePoint Web application. Aborting execution!"
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
               # For publishingwebs, check all publishingpages
               if ([Microsoft.SharePoint.Publishing.PublishingWeb]::IsPublishingWeb($web))
               {
                  $pubweb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($web)
                  $pages = $pubweb.GetPublishingPages()
                  foreach($page in $pages)
                  {
                     Get-CEWP -url $page.Url
                  }
               }
                    
               # Libraries and lists have views and forms which can contain webparts... let's get them also
               $lists = $web.GetListsOfType("DocumentLibrary") | ? {$_.IsCatalog -eq $false}
               foreach ($list in $lists)
               {
                  # Check the views
                  $views = $list.Views
                  foreach ($view in $views)
                  {
                     Get-CEWP -url $view.Url
                  }
                        
                  # Check the forms
                  $forms = $list.Forms
                  foreach ($form in $forms)
                  {
                     Get-CEWP -url $form.Url
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