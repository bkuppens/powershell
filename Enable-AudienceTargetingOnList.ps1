<#
.SYNOPSIS
    Enables audience targeting on a SharePoint list or library.
	
.DESCRIPTION
    Enables audience targeting on a SharePoint list or library.
    This will add an extra column to all associated content types.
    This makes it important to do this AFTER you added the content 
    types to the list or library.
	
.NOTES
    File Name: Enable-AudienceTargetingOnList.ps1
    Author   : Bart Kuppens
    Version  : 1.0
	
.PARAMETER Web
    Specifies the URL for the web where the library is located.
	
.PARAMETER ListName
    Specifies the name of the list where you want to enable audience targeting.
	
.EXAMPLE
    PS > .\Enable-AudienceTargeting.ps1 -Web http://teamsites.westeros.local -ListName Documents

    Description
    -----------
    Enables audience targeting on the "Documents" library on http://teamsites.westeros.local.
#>
[CmdletBinding()]
param(
    [parameter(Position=0,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the URL for the web where the library is located.")]
    [string]$Web,
    [parameter(Position=1,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Specifies the name of the list where you want to enable audience targeting.")]
    [string]$ListName
)

# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
    Write-Host "Loading the SharePoint PowerShell snapin..."
    Add-PSSnapin Microsoft.SharePoint.PowerShell
}	
	
$SPWeb = Get-SPWeb $Web -EA SilentlyContinue
if ($SPWeb -eq $null)
{
    Write-Error "$Web is not a valid SharePoint Web"
}
else
{
    Try
    {	
        $fieldID = "61cbb965-1e04-4273-b658-eedaa662f48d"
        [Guid]$AudFieldID = New-Object System.Guid($fieldID)
		
        $list = $SPWeb.Lists[$ListName]
        if ($list -ne $null)
        {
            # Check if audience targeting is already enabled on this list.
            $audField = $list.Fields[$AudFieldID]
            if ($audField -eq $null)
            {
                # Not yet enabled, enable it
                $xmlField = New-Object System.Xml.XmlDocument
                $field = $xmlField.CreateElement("Field")
                $field.SetAttribute("ID",$fieldID)
                $field.SetAttribute("Type","TargetTo")
                $field.SetAttribute("Name","TargetTo")
                $field.SetAttribute("DisplayName","Target Audiences")
                $field.SetAttribute("Required","FALSE")
                $list.Fields.AddFieldAsXml($field.OuterXml) >> $null
                $list.Update()
                Write-Host -ForegroundColor Green "Audience targeting is succesfully enabled on '$ListName'"
            }
            else
            {
                Write-Host -ForegroundColor Yellow "Audience targeting is already enabled on '$ListName'"
            }
        }
        else
        {
	    Write-Host "The list with the name $ListName was not found on $($SPWeb.Url)"
        }
    }
    catch
    {
        Write-Error $_.Exception
    }
    finally
    {
        $SPWeb.Dispose()
    }
}