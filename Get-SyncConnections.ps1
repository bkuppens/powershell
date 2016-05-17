<# 
    .SYNOPSIS
       Get the synchronization connections from the User Profile Service Application.
 
    .DESCRIPTION
       Get the synchronization connections from the User Profile Service Application.

    .NOTES
       File Name: Get-SyncConnections.ps1  
       Author   : Bart Kuppens
       Version  : 1.0

    .PARAMETER OutputFile
       Specifies the name of the file where the output is written to.   

    .EXAMPLE
       PS C:\> .\Get-SyncConnections.ps1 -OutputFile "c:\temp\connections.xml" 
#> 
[CmdletBinding()] 
param(
    [parameter(Position=0,Mandatory=$true,ValueFromPipeline=$false)]  
    [string]$OutputFile)

# Load the SharePoint PowerShell snapin if needed 
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -EA SilentlyContinue) -eq $null) 
{
    Write-Host "Loading the SharePoint PowerShell snapin..."
    Add-PSSnapin Microsoft.SharePoint.PowerShell
}

$ups = @(Get-SPServiceApplication | ? {$_.TypeName -eq "User Profile Service Application"})[0]

$context = [Microsoft.SharePoint.SPServiceContext]::GetContext($ups.ServiceApplicationProxyGroup,[Microsoft.SharePoint.SPSiteSubscriptionIdentifier]::Default)
$upcm = New-Object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($context)

$xml = new-object xml
$root = $xml.CreateElement("Connections")
$xml.AppendChild($root) >> $null

# Get AD Connections 
$ADConnections = $upcm.ConnectionManager | ? {$_.Type -eq "ActiveDirectory"} 
foreach ($ADConnection in $ADConnections)
{
    $xeConnection = $xml.CreateElement("Connection")
    $xaConnectionName = $xml.CreateAttribute("Name")
    $xaServer = $xml.CreateAttribute("Server")
    $xaUseSSL = $xml.CreateAttribute("UseSSL")
    $xaSyncAccount = $xml.CreateAttribute("SyncAccount")
    $xaType = $xml.CreateAttribute("Type")

    $xaServer.Value = $ADConnection.Server
    $xaUseSSL.Value = $ADConnection.UseSSL
    $xaSyncAccount.Value = "$($ADConnection.AccountDomain)\$($ADConnection.AccountUsername)"    
    $xaConnectionName.Value = $ADConnection.DisplayName
    $xaType.Value = $ADConnection.Type
 
    $xeConnection.Attributes.Append($xaSyncAccount) >> $null
    $xeConnection.Attributes.Append($xaUseSSL) >> $null
    $xeConnection.Attributes.Append($xaServer) >> $null
    $xeConnection.Attributes.Append($xaType) >> $null
    $xeConnection.Attributes.Append($xaConnectionName) >> $null

    # Enumerate all NamingContexts
    foreach ($nc in $ADConnection.NamingContexts)
    {
       $xeNamingContext = $xml.CreateElement("NamingContext")
       $xaDistinguisedName = $xml.CreateAttribute("DistinguishedName")
       $xaDomainName = $xml.CreateAttribute("DomainName")
       $xaIsDomain = $xml.CreateAttribute("IsDomain")
       $xaIsConfigNC = $xml.CreateAttribute("IsConfigurationContext")

       $xaDistinguisedName.Value = $nc.DistinguishedName
       $xaDomainName.Value = $nc.DomainName
       $xaIsDomain.Value = $nc.IsDomain
       $xaIsConfigNC.Value = $nc.IsConfigurationNamingContext

       $xeNamingContext.Attributes.Append($xaIsConfigNC) >> $null
       $xeNamingContext.Attributes.Append($xaIsDomain) >> $null
       $xeNamingContext.Attributes.Append($xaDomainName) >> $null
       $xeNamingContext.Attributes.Append($xaDistinguisedName) >> $null
       $xeConnection.AppendChild($xeNamingContext) >> $null

       foreach ($container in $nc.ContainersIncluded)
       {
          $xeIncludedContainer = $xml.CreateElement("IncludedContainer")
          $xaContainerName = $xml.CreateAttribute("DN")
          $xaContainerName.Value = $container
          $xeIncludedContainer.Attributes.Append($xaContainerName) >> $null
          $xeNamingContext.AppendChild($xeIncludedContainer) >> $null
       }

       foreach ($container in $nc.ContainersExcluded)
       {
          $xeExcludedContainer = $xml.CreateElement("ExcludedContainer")
          $xaContainerName = $xml.CreateAttribute("DN")
          $xaContainerName.Value = $container
          $xeExcludedContainer.Attributes.Append($xaContainerName) >> $null
          $xeNamingContext.AppendChild($xeExcludedContainer) >> $null
       }
    }

    $root.AppendChild($xeConnection) >> $null 
} 
$xml.OuterXml > $OutputFile