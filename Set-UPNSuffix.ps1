<#
.SYNOPSIS
   Change UPN Suffix for users in AD.

.DESCRIPTION
   Change UPN Suffix for users in AD.
	
.NOTES
   File Name: Set-UPNSuffix.ps1
   Author   : Bart Kuppens
   Version  : 1.0

.PARAMETER OldUPNSuffix
   Specifies the old UPN suffix (without the @ sign)

.PARAMETER NewUPNSuffix
   Specifies the new UPN suffix (without the @ sign)

.PARAMETER Filter
   Specifies the filter to use for the scope of users

.PARAMETER Mode
   Specifies the run mode (Modify, List)

.EXAMPLE
   PS > .\Set-UPNSuffix.ps1 -OldUPNSuffix "westeros.local" -NewUPNSuffix "westeros.com" -Filter "employeeType -eq 'E'" -Mode "Modify"
#>
[CmdletBinding()]
param(
   [parameter(Position=0,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the old UPN suffix (without the @ sign).")]
   [string]$OldUPNSuffix,
   [parameter(Position=1,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the new UPN suffix (without the @ sign).")]
   [string]$NewUPNSuffix,
   [parameter(Position=2,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the filter to use for the scope of users.")]
   [string]$Filter,
   [parameter(Position=3,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the run mode (Modify, List).")]
   [ValidateSet("Modify","List")]$Mode
)

$LogFile = "C:\temp\UPNSuffixChanges_" + $([DateTime]::Now.ToString('yyyyMMdd')) + ".log"
function Write-Log([string]$message)
{
   Out-File -InputObject $message -FilePath $LogFile -Append
}

# Check if the ActiveDirectory module is installed
$modules = Get-Module -ListAvailable
if (($modules | ? {$_.Name -eq "ActiveDirectory"}) -eq $null)
{
   Write-Host -ForegroundColor Yellow "The Active Directory module is not installed, halting execution!"
   break
}

# Load the Active Directory module if needed
if (-not (Get-Module ActiveDirectory))
{
   Import-Module ActiveDirectory            
}            

# Check if the specified UPN Suffix exists in the domain
$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$domaindn = ($domain.GetDirectoryEntry()).distinguishedName
$upnDN = "cn=Partitions,cn=Configuration,$domaindn"
$upnSuffixes = Get-ADObject -Identity $upnDN -Properties upnsuffixes | select -ExpandProperty upnsuffixes

if ($upnSuffixes.Contains($UPNSuffix))
{
   $users = Get-ADUser -Filter $Filter
   Write-Host "Number of users found: $($users.Count)"
   foreach ($user in $users)
   {
      if (!($user.UserPrincipalName.ToLower().Contains($oldUPNSuffix)))
      {
         $message = "User $($user.UserPrincipalName) cannot be changed due to wrong suffix"
         Write-Log "ERROR: $message"
      }
      else
      {
         $newUpn = $user.UserPrincipalName.Replace($OldUPNSuffix,$NewUPNSuffix)
         if ($Mode -eq "Modify")
         {
            Set-ADUser $user -server $env:COMPUTERNAME -UserPrincipalName $newUpn
            $message = "The UPN suffix for user $($user.UserprincipalName) is changed to $newUpn"
            Write-Log "INFO: $message"
         }
         else
         {
            $message = "The UPN suffix for user $($user.UserprincipalName) will change to $newUpn" 
            Write-Log "INFO: $message"
         }
      }
   }
}
else
{
   Write-Host -ForegroundColor Yellow "The UPN suffix '$UPNSuffix' is not valid in this domain, halting execution!"
   break
}