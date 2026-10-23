. .\BTSAdminFunctions.ps1
. .\BTSConfigs.ps1
[System.reflection.Assembly]::LoadWithPartialName("Microsoft.BizTalk.ExplorerOM") | Out-Null


# Get List of Installers
$UnInstallers=[string[]](Get-ChildItem 'C:\BizTalk\Current\*.msi' -Recurse).FullName

# Get List of Installers
$Installers=[string[]](Get-ChildItem 'C:\BizTalk\Install\*.msi' -Recurse).FullName

$InstallValid=$true

# No Installers. Exit cleanly.
if ($Installers.Count -eq 0)
{
    Write-Host "INFO: Nothing to Install..." -ForegroundColor Yellow
    $InstallValid=$false
}
else
{	
	# Check for multiple installers.
    foreach ($BTSApp in $BTSApps)
    {
        $subList=($Installers -like "*$BTSApp-*")
        if ($subList.Count -gt 1)
        {
            Write-Host "ERROR: Too many installers for $BTSApp..." -ForegroundColor Red
            $InstallValid=$false
        }
	}
}

# Check to see if we are currently running "as Administrator"
if ($Host.UI.RawUI.WindowTitle -notlike 'Administrator: *')
{
	Write-Host "ERROR: Not running as Administrator!" -ForegroundColor Red
	$InstallValid=$false
}

# Check to see if we are currently running "as x86"
if ($Host.UI.RawUI.WindowTitle -notlike '*x86*')
{
	Write-Host "ERROR: Not running as x86!" -ForegroundColor Red
	$InstallValid=$false
}

if ($InstallValid -eq $true)
{
	DisableAllReceiveLocations
	WaitForIDLE
    #$restartInstances = @()
    $appsTobeInstalled = @()

	foreach ($BTSApp in $BTSApps)
	{
		$subList=($Installers -like "*$BTSApp-*")
		if ($subList.Count -eq 1)
		{
			$appsTobeInstalled += $BTSApp
			#$restartInstances += ($applicationHostInstanceArrayList | Where-Object { $_[0] -eq $BTSApp })[1]
		}
	}
	
	#$restartInstances = ($restartInstances | Select-Object -Unique)

 	$Installers=(Get-ChildItem 'C:\BizTalk\Install\*.msi' -Recurse).FullName

	if ($FirstServerForUndeploy -eq "true")
	{
		<#
		if ($serverGroup -ne $null)
		{

			$secondaryServers=$serverGroup[1]
			foreach ($server in $SecondaryServers)
			{
				#Write-Host "Copying Installers to $server..." -ForegroundColor Green
				#Copy-Item c:\BizTalk\Releases\ToBeInstalled \\$server\c$\BizTalk\Releases -Force -recurse 
			}
		}
		#>

		$appsToBeUninstalled = $appsTobeInstalled
		[array]::Reverse($appsToBeUninstalled)

	    Write-Host "Uninstalling Current Apps..." -ForegroundColor Green
        foreach ($BTSApp in $appsToBeUninstalled)
        {
            StopApp $BTSApp
			#Write-Host "Uninstalling"$BTSApp"..." -ForegroundColor Green
			UninstallApp $BTSApp $Installers
        }
	}

	Start-Sleep -s 30
	
	[array]::Reverse($appsTobeInstalled)

	Write-Host "Installing New Apps..." -ForegroundColor Green
    foreach ($BTSApp in $appsTobeInstalled)
    {
        InstallApp $BTSApp
    }

	Remove-Item -Path 'C:\BizTalk\Current\*'
	Move-Item -Path 'C:\BizTalk\Install\*' -Destination 'C:\BizTalk\Current'
}
