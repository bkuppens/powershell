<#
.SYNOPSIS
	Creates a BackConnectionHostNames key in the registry.

.DESCRIPTION
	Creates a BackConnectionHostNames key in the registry.

.NOTES
	File Name: Add-BackConnectionHostNamesKey.ps1
	Author   : Bart Kuppens - CTG Belgium
	Version  : 1.0

.PARAMETER HostNames
	Specifies the hostnames for the BackConnectionHostNames key as a comma-delimited list.
	
.EXAMPLE
	PS > .\Add-BackConnectionHostNamesKey.ps1 -HostNames "intranet.ctgdemo.com,teamsites.ctgdemo.com"
#>
[CmdletBinding()]
param(
	[parameter(Position=0,Mandatory=$false,ValueFromPipeline=$false)]
	[string]$HostNames
)


[System.String[]]$AdditionalUrlsArray = $null
if ($HostNames -ne $null -and $HostNames.Length -gt 0)
{
	$AdditionalUrlsArray = $HostNames.Split(",")
}

[string]$path = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0\"
[string]$name = "BackConnectionHostNames"

if ((Get-ItemProperty -Path $path -Name $name -ea silentlycontinue) -eq $null)
{
	New-ItemProperty HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0 -Name “BackConnectionHostNames” -Value "" -PropertyType multistring
}
else
{
	Write-Output "BackConnectionHostNames already exists!"
	[string]$currentvalue = (Get-Item "$path").GetValue("$name")
	[System.String[]]$ExistingValues = "$currentvalue".Split()
	ForEach ($currentAlias in $ExistingValues)
	{
		if ($currentAlias)
		{
			if ($newAlias)
			{
				If($ArrayNewUrls -notcontains $currentAlias)
				{
					$newAlias = $newAlias+" "+$currentAlias                                                            
				}
			}
			Else
			{
				$newAlias = $currentAlias
			}
		}
		[System.String[]]$ArrayNewUrls = "$newAlias".Split()
	}
	ForEach ($addAlias in $ArrayAdditionalUrls)
	{
		If ($ExistingValues -notcontains $addAlias)
		{
			$newAlias = $newAlias+" "+$AddAlias   
		}
	}
}
               
$newAlias = $newAlias.Trim()
[System.String[]]$ArrayNewUrls = "$newAlias".Split()

Set-ItemProperty -Path $path -Name $name -Value ([string[]]$ArrayNewUrls)