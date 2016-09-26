<#
.SYNOPSIS
   Checks for disconnected sessions and logs off the disconnected user sessions.

.DESCRIPTION
   Checks for disconnected sessions and logs off the disconnected user sessions.

.NOTES
   File Name: Logoff-DisconnectedSession.ps1
   Author   : Bart Kuppens
   Version  : 1.1

.EXAMPLE
   PS > .\Logoff-DisconnectedSession.ps1
#>

function Ensure-LogFilePath([string]$LogFilePath)
{
    if (!(Test-Path -Path $LogFilePath)) {New-Item $LogFilePath -ItemType directory >> $null}
}

function Write-Log([string]$message)
{
   Out-File -InputObject $message -FilePath $LogFile -Append
}

function Get-Sessions
{
   $queryResults = query session
   $starters = New-Object psobject -Property @{"SessionName" = 0; "UserName" = 0; "ID" = 0; "State" = 0; "Type" = 0; "Device" = 0;}
   foreach ($result in $queryResults)
   {
      try
      {
         if($result.trim().substring(0, $result.trim().indexof(" ")) -eq "SESSIONNAME")
         {
            $starters.UserName = $result.indexof("USERNAME");
            $starters.ID = $result.indexof("ID");
            $starters.State = $result.indexof("STATE");
            $starters.Type = $result.indexof("TYPE");
            $starters.Device = $result.indexof("DEVICE");
            continue;
         }

         New-Object psobject -Property @{
            "SessionName" = $result.trim().substring(0, $result.trim().indexof(" ")).trim(">");
            "Username" = $result.Substring($starters.Username, $result.IndexOf(" ", $starters.Username) - $starters.Username);
            "ID" = $result.Substring($result.IndexOf(" ", $starters.Username), $starters.ID - $result.IndexOf(" ", $starters.Username) + 2).trim();
            "State" = $result.Substring($starters.State, $result.IndexOf(" ", $starters.State)-$starters.State).trim();
            "Type" = $result.Substring($starters.Type, $starters.Device - $starters.Type).trim();
            "Device" = $result.Substring($starters.Device).trim()
         }
      } 
      catch 
      {
         $e = $_;
         Write-Log "ERROR: " + $e.PSMessageDetails
      }
   }
}

Ensure-LogFilePath($ENV:LOCALAPPDATA + "\DisconnectedSessions")
$LogFile = $ENV:LOCALAPPDATA + "\DisconnectedSessions\" + "sessions_" + $([DateTime]::Now.ToString('yyyyMMdd')) + ".log"

[string]$IncludeStates = '^(Disc)$'
Write-Log -Message "Disconnected Sessions CleanUp"
Write-Log -Message "============================="
$DisconnectedSessions = Get-Sessions | ? {$_.State -match $IncludeStates -and $_.UserName -ne ""} | Select ID, UserName
Write-Log -Message "Logged off sessions"
Write-Log -Message "-------------------"
foreach ($session in $DisconnectedSessions)
{
   logoff $session.ID
   Write-Log -Message $session.Username
}
Write-Log -Message " "
Write-Log -Message "Finished"
