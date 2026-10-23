#if ( ($env:computername -eq 'DEV-SS-WARE') -or ($env:computername -eq 'DEV-SS-ADI') )
#{
#    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -force >$null
#}

$InitializeDefaultBTSDrive = $false
Add-PSSnapin -Name BizTalkFactory.PowerShell.Extensions
[void] [System.reflection.Assembly]::LoadWithPartialName("Microsoft.BizTalk.ExplorerOM")


function CreateHost
{
    param([string]$HostName, [string]$HostType, [boolean]$AuthTrusted, [string]$NTGroupName, 
    [boolean]$Is32BitOnly, [boolean]$IsTrackingHost, [boolean]$IsDefault)
    
    # Check if host exists
    if (test-path "BizTalk:\Platform Settings\Hosts\$HostName")
    {    
        #Host exists no action necessary
        Write-host "Host $HostName Already Exists." -ForegroundColor Yellow
    }
    else
    {
        # Create Host
		Write-Host "Creating host: $HostName..." -ForegroundColor Green

	    #Set-Location 'BizTalk:\Platform Settings\Hosts'
        New-Item -Path:"BizTalk:\Platform Settings\Hosts\$HostName" -HostType:$HostType -NtGroupName:$NTGroupName -AuthTrusted:$AuthTrusted >$null
        Set-ItemProperty -Path:"BizTalk:\Platform Settings\Hosts\$HostName" -Name:HostTracking -Value:$IsTrackingHost
        Set-ItemProperty -Path:"BizTalk:\Platform Settings\Hosts\$HostName" -Name:Is32BitOnly -Value:$Is32BitOnly
        
        if ($IsDefault)
        {
            Set-ItemProperty -Path:"BizTalk:\Platform Settings\Hosts\$HostName" -Name:IsDefault -Value:$IsDefault
        }
    }
}

function CreateHandler
{
    param([string]$AdapterName, [string]$HostName, [string]$Direction, [boolean]$Default, [string[]]$existingHandlers )    
    
    $handlerName = "$AdapterName $Direction Handler ($HostName)"

    if ($existingHandlers -contains $handlerName)
    {    
        Write-host "Handler Already Exists: $HostName for ($AdapterName,$Direction)." -ForegroundColor Yellow
    }
    else
    {
	    Write-Host "Creating Handler: $HostName for ($AdapterName,$Direction)..." -ForegroundColor Green
		Set-Location "BizTalk:\Platform Settings\Adapters\$AdapterName"

	    if ($Direction -eq 'Send')
	    {
		    New-Item -path '.\Dummy' -hostname $HostName -direction $Direction -Default:$Default >$null
	    }
	
	    else
	    {    
		    New-Item -path '.\Dummy' -hostname $HostName -direction $Direction >$null 
	    }
    }
}

function CreateHostInstance
{
    param([string]$HostName, [string]$serverName, [string]$AccountName, [string]$Password)
    
	$fullHostName = "$HostName $serverName"
    if (test-path "BizTalk:\Platform Settings\Host Instances\Microsoft BizTalk Server $fullHostName")
    {
        Write-host "Host Instance $fullHostName already Exists." -ForegroundColor Yellow
    }

    else
    {
	    Write-Host "Creating Host Instance $fullHostName..." -ForegroundColor Green
		Set-Location "BizTalk:\Platform Settings\Host Instances"

	    $HostPassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
	    $HostisoPassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
	    $HostCredentials = New-Object -TypeName:System.Management.Automation.PSCredential -ArgumentList $AccountName, $HostPassword
	    #$HostisoCredentials = New-Object -TypeName:System.Management.Automation.PSCredential -ArgumentList $AccountName, $HostisoPassword

		New-Item $HostName -HostName $HostName -Credentials $HostCredentials -RunningServer $serverName >$null
    }
}

function StopHostInstance
{
    param([string]$BTSServer, [string]$HostInstanceName)    

    Write-Host "Stopping $inst..." -ForegroundColor Red
    $hostInst = 'BizTalk:\Platform Settings\Host Instances\Microsoft BizTalk Server '+$HostInstanceName+' '+ $BTSServer
    Stop-HostInstance -Path $hostInst
}

function ReStartHostInstance
{
    param([string]$BTSServer, [string]$HostInstanceName)    

    Write-Host "ReStarting $HostInstanceName on $BTSServer..." -ForegroundColor Green
	$instanceName = "Microsoft BizTalk Server $HostInstanceName $BTSServer"
	$instance = (Get-WmiObject -Class "MSBTS_HostInstance" -Namespace 'root\MicrosoftBizTalkServer' -Filter "HostType='1'" | Where-Object { $_.Name -match $instanceName })
    if ($instance.ServiceState -eq 4)
    {
	    $instance.Stop() >$null
	    $instance = (Get-WmiObject -Class "MSBTS_HostInstance" -Namespace 'root\MicrosoftBizTalkServer' -Filter "HostType='1'" | Where-Object { $_.Name -match $instanceName })
    }

    if ($instance.ServiceState -eq 1)
    {
	    $instance.Start() >$null
	    $instance = (Get-WmiObject -Class "MSBTS_HostInstance" -Namespace 'root\MicrosoftBizTalkServer' -Filter "HostType='1'" | Where-Object { $_.Name -match $instanceName })
    }

    if ($instance.ServiceState -eq 4)
    {
        Write-Host "Host Instance $HostInstanceName on $BTSServer restarted..." -ForegroundColor Green
    }
    else
    {
        Write-Host "ERROR: Host Instance $HostInstanceName on $BTSServer NOT restarted..." -ForegroundColor Red
    }
}

function StartHostInstance
{
    param([string]$BTSServer, [string]$HostInstanceName)    

    Write-Host "Starting $HostInstanceName..." -ForegroundColor Green
    $hostInst = 'BizTalk:\Platform Settings\Host Instances\Microsoft BizTalk Server '+$HostInstanceName+' '+ $BTSServer
    Start-HostInstance -Path $hostInst
}

function StopAllHostInstances
{
    Write-Host "Stopping All Host Instances..." -ForegroundColor Green

    $hostInstances = (Get-ChildItem 'BizTalk:\Platform Settings\Host Instances').Name    
    foreach ($inst in $hostInstances)
    {
        Write-Host "Stopping $inst..." -ForegroundColor Green
        Stop-HostInstance -Path "BizTalk:\Platform Settings\Host Instances\$inst"
    }
}

function StartAllHostInstances
{
    Write-Host "Starting All Host Instances..." -ForegroundColor Green
	
    $hostInstances = (Get-ChildItem 'BizTalk:\Platform Settings\Host Instances').Name    
    foreach ($inst in $hostInstances)
    {
        Write-Host "Starting $inst..." -ForegroundColor Green
        Start-HostInstance -Path "BizTalk:\Platform Settings\Host Instances\$inst"
    }
}

function GetReferencingApps( [string] $appName )
{
    $list = @()

    $apps = Get-ChildItem( 'BizTalk:\Applications' )

    foreach ($app in $apps.Name)
    {
        if (test-path "BizTalk:\Applications\$app\References\$appName")
        {
            $list += $app
        }
    }

    
    return ,$list
}

function RemoveAppReferences
{
    param([string]$BTSApp, [string[]]$Applications)

    foreach ($app in $Applications)
    {
        if (test-path "BizTalk:\Applications\$app\References\$BTSApp")
        {
            Remove-ApplicationReference -Path "BizTalk:\Applications\$app" -References $BTSApp
        }
        else
        {
            Write-Host "INFO: Reference does not exist from $app to $BTSApp..." -ForegroundColor Yellow
        }
    }
}

function AddAppReferences
{
    param([string]$BTSApp, [string[]]$Applications)

    foreach ($app in $Applications)
    {
        if ((test-path "BizTalk:\Applications\$app\References\$BTSApp") -eq $false)
        {
            Add-ApplicationReference -Path "BizTalk:\Applications\$app" -References $BTSApp
        }
        else
        {
            Write-Host "INFO: Reference already exists from $app to $BTSApp..." -ForegroundColor Yellow
        }
    }
}

function GetAppDependencies
{
    $dependencies = @{}

    $Apps = Get-ChildItem( 'BizTalk:\Applications' )
    $Apps = $Apps.Name

    foreach ($App in $Apps)
    {
        $references = Get-ChildItem( "BizTalk:\Applications\$App\Back References" )
        $references = $references.Name
        $dependencies.Add($App, $references)
    }

    return $dependencies
}

<#
function UpdateToBeInstalledFromCurrent
{
    param([string]$BTSApp, [string[]]$Installers, [hashtable] $dependencies)

	$subList=($Installers -like "*$BTSApp-*")

    if ($subList.Count -gt 0)
    {
        foreach ($refApp in $dependencies[$BTSApp])
        {
            $refInstaller=($Installers -like "*$refApp-*")
            if ($refInstaller.Count -eq 0)
            {
                Write-Host "Getting Dependent Installers from Current for $refApp..." -ForegroundColor Green
                $currentMSI = Get-ChildItem("c:\BizTalk\Current\*$refApp-*.msi")
                Copy-Item $currentMSI c:\BizTalk\Install\$refApp
            }
            else
            {
                Write-Host "INFO: No Dependent Installers to get." -ForegroundColor Yellow
            }

        }
        
    }
}
#>

function StartApp([string]$BTSApp)
{
    if (Test-Path BizTalk:\Applications\$BTSApp) 
    {
        Write-Host "Starting Send Ports for $BTSApp..." -ForegroundColor Green
        Start-Application BizTalk:\Applications\$BTSApp -StartOption StartAllSendPorts

        Write-Host "Starting Orchestrations for $BTSApp..." -ForegroundColor Green
        Start-Application BizTalk:\Applications\$BTSApp -StartOption StartAllOrchestrations
    }
    else
    {
        Write-Host "$BTSApp Does Not exist..." -ForegroundColor Yellow
    }
}

function StopApp([string]$BTSApp)
{
    if (Test-Path BizTalk:\Applications\$BTSApp) 
    {
        Write-Host "Stopping $BTSApp..." -ForegroundColor Green
        Stop-Application BizTalk:\Applications\$BTSApp -StopOption UnenlistAllOrchestrations
        Stop-Application BizTalk:\Applications\$BTSApp -StopOption UnenlistAllSendPorts									   
    }
    else
    {
        Write-Host "$BTSApp Does Not exist..." -ForegroundColor Yellow
    }
}

function UninstallApp
{
    param([string]$BTSApp, [string[]]$Installers)    

	$subList=($Installers -like "*$BTSApp-*")
    if (Test-Path BizTalk:\Applications\$BTSApp) 
    {
		# Remove the App from the first server that does this step.
		if ($subList.Count -eq 1)
		{
			if ($FirstServerForUndeploy -eq "true")
			{
				Write-Host "Uninstalling $BTSApp..." -ForegroundColor Green
				StopApp $BTSApp
				BTSTask RemoveApp /ApplicationName:$BTSApp /Server:$TargetServer /Database:BizTalkMgmtDb
			}
		}
    }
    else
    {
        Write-Host "$BTSApp Does Not exist..." -ForegroundColor Yellow
    }

	# Do this for any Server to remove from GAC
	if ($subList.Count -eq 1)
	{
		$CurrentMSI = (Get-ChildItem c:\BizTalk\Current\$BTSApp-*.msi).FullName
		msiexec /uninstall $CurrentMSI /passive
	    $MSIVersion=$CurrentMSI -replace "c:\\BizTalk\\Current\\", '' -replace "$BTSApp-", '' -replace ".msi", ''
		$uninstallAppPath = "C:\Program Files (x86)\$BTSApp"
		$uninstallAppPath
		Remove-Item -Path $uninstallAppPath -Recurse
	}
	else
	{
		Write-Host "NOT Uninstalling $BTSApp. Nothing to replace with." -ForegroundColor Green
	}
}

function UnDeployApp
{
    param([string]$BTSApp, [string[]]$Installers)    

	$subList=($Installers -like "*$BTSApp-*")
    if (Test-Path BizTalk:\Applications\$BTSApp) 
    {
		# Remove the App from the first server that does this step.
		if ($subList.Count -eq 1)
		{
			if ($FirstServerForUndeploy -eq "true")
			{
				Write-Host "Undeploying $BTSApp..." -ForegroundColor Green
				BTSTask RemoveApp /ApplicationName:$BTSApp /Server:$TargetServer /Database:BizTalkMgmtDb
			}
		}
    }
    else
    {
        Write-Host "$BTSApp Does Not exist..." -ForegroundColor Yellow
    }
}


function InstallApp
{
    param([string]$AppName)
    
    #$refApps = GetReferencingApps( $AppName )

    Write-Host "Installing $AppName..." -ForegroundColor Green
    $MSICount=( Get-ChildItem 'c:\BizTalk\Install\'$AppName'-*.msi').Count

    if ($MSICount -eq 0)
    {
	    Write-Host "No Installer for $AppName" -ForegroundColor Yellow
    }
    ElseIf ($MSICount -gt 1)
    {
	    Write-Host "Multiple Installers for $AppName" -ForegroundColor Red
    }
    else
    {
        $MSIFile=( Get-ChildItem 'c:\BizTalk\Install\'$AppName'-*.msi')
	    $MSIName=$MSIFile.FullName
	    $MSIVersion=$MSIFile.Name -replace "$AppName-", '' -replace '.msi', ''
		#$logFile = """C:\Program Files (x86)\VU.ESB.Common\$AppName-$MSIVersion.log"""
        $MSIArgs = @(
            "/i"
            ('"{0}"' -f $MSIName)
            '/passive'
            #'/l'
            #$logFile
            "INSTALLDIR=""C:\Program Files (x86)\$AppName\$MSIVersion\"""
        )
		
		#$MSIArgs
        Start-Process msiexec.exe -ArgumentList $MSIArgs -Wait 
        
		$MSIBuildArgs = @(
            "/p:DeployBizTalkMgmtDB=$LastServerForDeploy;Configuration=Server;SkipUndeploy=true"
            "/target:Deploy" 
            "/l:FileLogger,Microsoft.Build.Engine;logfile=""C:\Program Files (x86)\$AppName\$MSIVersion\DeployResults\DeployResults.txt"""
            """C:\Program Files (x86)\$AppName\$MSIVersion\Deployment\Deployment.btdfproj"""
            "/p:BTSACCOUNT=$ServiceHostAccountName"
            "/p:ENV_SETTINGS=""C:\Program Files (x86)\$AppName\$MSIVersion\Deployment\EnvironmentSettings\$BindingsFileName"""
        )

		Write-Host "Deploying $AppName..." -ForegroundColor Green
        #$MSIBuildArgs
        Start-Process $env:windir\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe -ArgumentList $MSIBuildArgs -Wait
    }
}

function ArchiveCurrent
{
    param([string]$AppName)    

    if (test-path c:\BizTalk\Install\$AppName-*.msi)
    {
        Write-Host "Archiving $AppName..." -ForegroundColor Green
        Move-Item -Path "c:\BizTalk\Current\$AppName-*.msi" -Destination c:\BizTalk\Archive -Force
    }
}


function InstalledToCurrent
{
    param([string]$AppName)    

    Write-Host "Moving to Current: $AppName..." -ForegroundColor Green
    Copy-Item -Path "c:\BizTalk\Install\$AppName-*.msi" -Destination c:\BizTalk\Current -Force
}


function EnableReceiveLocation($appName, $rcvLocationName, $status)
{
    if ($status -eq $true)
    {
        Enable-ReceiveLocation -Path "BizTalk:\Applications\$appName\Receive Locations\$rcvLocationName"
    }
    else
    {
        Disable-ReceiveLocation -Path "BizTalk:\Applications\$appName\Receive Locations\$rcvLocationName"
    }
}

function DisableAllReceiveLocations()
{
	Write-Host "Disabling All Receive Locations..." -ForegroundColor Green

    foreach ($app in (Get-ChildItem 'BizTalk:\Applications').Name)
    {
		"Disabling All Receive Locations for $app..."

        foreach ($loc in (Get-ChildItem "BizTalk:\Applications\$app\Receive Locations"))
        {
            if ($loc.Enable -eq $true)
            {
                $locName = $loc.Name
                Write-Host "Disabling Location $locName..." -ForegroundColor Green
                Disable-ReceiveLocation -Path "BizTalk:\Applications\$app\Receive Locations\$locName"
            }
			else
			{
                Write-Host "Location already disabled: "$loc.Name"." -ForegroundColor Yellow
			}
        }
    }
}

function EnableAllReceiveLocations()
{
    foreach ($app in (Get-ChildItem 'BizTalk:\Applications').Name)
    {
        foreach ($loc in (Get-ChildItem "BizTalk:\Applications\$app\Receive Locations"))
        {
            if ($loc.Enable -eq $false)
            {
                $locName = $loc.Name
                Write-Host "Enabling Location $locName..." -ForegroundColor Green
                Enable-ReceiveLocation -Path "BizTalk:\Applications\$app\Receive Locations\$locName"
            }
        }
    }
}

function UnenlistOrchestrations
{
    param([string[]]$orchestrations)

    foreach ($orch in $orchestrations)
    {
        Write-Host "Unenlisting $orch..." -ForegroundColor Green
        Unenlist-Orchestration -Path $orch
    }       
}

#Function to Enable/Disable All Receive Locations for Application except for those in $ignoreReceiveLocs
function EnableReceiveLocations( [string[]]$appNames, $status, [string[]]$ignoreReceiveLocs )
{
	$appList = $appNames -Join ", "
	$ignoreList = $ignoreReceiveLocs -Join ", "
	
	if ($status -eq $false)
	{
		Write-Host "Disabling Receive Locations for Apps($appList) except for Locations($ignoreList)..." -ForegroundColor Green
	}
	else
	{
		Write-Host "Enabling Receive Locations for Apps($appList) except for Locations($ignoreList)..." -ForegroundColor Green
	}

	foreach ($appName in $appNames)
	{
		$receiveLocationPath = "BizTalk:\Applications\$appName\Receive Locations"

		foreach ($recvLocation in (Get-ChildItem $receiveLocationPath).Name)
		{
			$location = "$receiveLocationPath\$recvLocation"
			if (($ignoreReceiveLocs -contains "$recvLocation") -eq $true)
			{
				Write-Host "Skipping $recvLocation..." -ForegroundColor Yellow
			}
			else
			{
				if ($status -eq $false)
				{
					Write-Host "Disabling Receive Location: $recvLocation..." -ForegroundColor Green
					Disable-ReceiveLocation -Path $location
				}
				else
				{
					Write-Host "Enabling Receive Location: $recvLocation..." -ForegroundColor Green
					Enable-ReceiveLocation -Path $location
				}
			}
		}
	}
}

function WaitForIDLE()
{
	Write-Host -NoNewline "Waiting for IDLE..." -ForegroundColor Yellow
	$bContinue = $true
	$iCount = 1
	while ($bContinue -eq $true)
	{
		if ((Get-ChildItem -Path 'BizTalk:\Health and Activity\Service Instances').Count -gt 0)
		{
			Write-Host -NoNewline "." -ForegroundColor Yellow
			Start-Sleep -m 1000
		}

		else
		{
			$iCount = $iCount + 1
			if ($iCount -lt 90)
			{
				Write-Host "." -ForegroundColor Green
				$bContinue = $false
			}
		}
	}

	Write-Host "IDLE reached." -ForegroundColor Green
}

function GetHostList
{
    Write-Host "Getting All Host Names..." -ForegroundColor Green

    $hosts = (Get-ChildItem 'BizTalk:\Platform Settings\Hosts').Name
	#$hosts
	return $hosts
}

function GetHostInstanceList
{
    Write-Host "Getting All Host Instances..." -ForegroundColor Green

    $hostInstances = (Get-ChildItem 'BizTalk:\Platform Settings\Host Instances').Name    
	#$hostInstances
	return $hostInstances
}

function EnableHostInstancesForServer( $serverName )
{
	Write-Host "Enabling Host Instances for Server $serverName..." -ForegroundColor Green
    $hostInst = Get-ChildItem('BizTalk:\Platform Settings\Host Instances')

    foreach( $hostinstEl in $hostInst) 
    { 
        if ($hostinstEl.RunningServer -eq $servername)
        {
            if ($hostinstEl.IsDisabled -eq $true)
            {
            	Write-Host "Enabling Host Instance "$hostinstEl.HostName"...." -ForegroundColor Green
                $hostinstEl.IsDisabled=$false ;
            }
            else
            {
            	Write-Host "Host Instance "$hostinstEl.HostName" Already enabled." -ForegroundColor Yellow
            }
        }
    }
}


function DisableHostInstancesForServer( $serverName )
{
	Write-Host "Disabling Host Instances for Server $serverName..." -ForegroundColor Green
    $hostInst = Get-ChildItem('BizTalk:\Platform Settings\Host Instances')

    foreach( $hostinstEl in $hostInst) 
    { 
        if ($hostinstEl.RunningServer -eq $servername)
        {
            if ($hostinstEl.IsDisabled -eq $false)
            {
            	Write-Host "Disabling Host Instance "$hostinstEl.HostName"...." -ForegroundColor Green
                $hostinstEl.IsDisabled=$true ;
            }
            else
            {
            	Write-Host "Host Instance "$hostinstEl.HostName" Already disabled." -ForegroundColor Yellow
            }
        }
    }
}