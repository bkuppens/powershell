<#
.SYNOPSIS
    Returns all termsets which are used for site navigation. 

.DESCRIPTION
    Returns all termsets which are used for site navigation. 

.NOTES
    File Name: Get-NavigationTermSets.ps1
    Author   : Bart Kuppens
    Version  : 2.0

.EXAMPLE
    PS > .\Get-NavigationTermSets.ps1

#>

# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -EA SilentlyContinue) -eq $null)
{
    Write-Host "Loading SharePoint cmdlets..."
    Add-PSSnapin Microsoft.SharePoint.PowerShell
}

$adminwebapp = Get-SPWebApplication -includecentraladministration | ? { $_.IsAdministrationWebApplication }
$caSite = Get-SPSite $adminwebapp.Url

$session = New-Object Microsoft.SharePoint.Taxonomy.TaxonomySession($caSite)
$termstores = $session.TermStores
foreach ($termstore in $termstores)
{
    $groups = $termstore.Groups
    foreach ($group in $groups)
    {
        $group.TermSets | ? {$_.CustomProperties["_Sys_Nav_IsNavigationTermSet"]}
    }
}