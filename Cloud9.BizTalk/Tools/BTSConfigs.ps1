. .\BTSAdminFunctions.ps1

$BTSApps = @( "Cloud9.Common", "Cloud9.BizTalk", "Cloud9.EDI" )
$IgnoreBTSApps = @()
$IgnoreReceiveLocations = @( )

$BTSServer = $env:computername
$ServerName=$env:computername

#Define Server Group List and the Server Group Array 
$serverGroupList =  @("WIN-IHP3RMGDGMF",@()),
					("LAB-BIZTALK1", @()),
                    ("LAB-BIZTALK1", @())
					
$serverGroup=($serverGroupList | Where-Object { $_[0] -eq $BTSServer })

#Define Application to Host Instance Mapping Array
$applicationHostInstanceArrayList =  @("Cloud9.Common", @("BizTalkServerApplication" )),
									  ("Cloud9.BizTalk", @("BizTalkServerApplication")),
									  ("Cloud9.EDI", @("BizTalkServerApplication"))

#Define MSI To Application Mapping Array
									  

#Define Server Settings list and object
#                       Server,BT Instance,First for Undeploy,Last for Deploy,Bindings File Name,Service Host Acct,NtGroupName   

$serverSettingsList = ("WIN-IHP3RMGDGMF","WIN-IHP3RMGDGMF\DEVSQLSVR2016","true","true", "Exported_AWARESettings.xml", ".\Administrator","BizTalk Application Users","0","WIN-IHP3RMGDGMF"),
					  ("LAB-BIZTALK1","lab-db1\labdb1instance","true","true", "Exported_LABSettings.xml", "CLOUD9\svcBT_UAT_BizTalkHos","CLOUD9\BizTalk-UAT_Application_Users","0","LAB"),
                      ("PROD","lab-db1\labdb1instance","true","true", "Exported_ProdSettings.xml", "CLOUD9\BT_App_Svc","CLOUD9\BizTalk-Application_Users","0","PROD") | 
					ForEach-Object {[pscustomobject]@{ Machine = $_[0]; Instance = $_[1]; FirstServerForUndeploy = $_[2]; LastServerForDeploy = $_[3]; BindingsFileName = $_[4]; ServiceHostAccountName = $_[5]; NtGroupName = $_[6]; DRInstance = $_[7]; FirstServerInGroup= $_[8]; } }
					
$serverSettings=($serverSettingsList | Where Machine -eq $env:computername)
if ($serverSettings -eq $null)
{
    Write-Host "ERROR: No Server settings for $env:computername." -ForegroundColor Red
}

$DatabaseName=$serverSettings.Instance
$FirstServerForUndeploy=$serverSettings.FirstServerForUndeploy 
$LastServerForDeploy=$serverSettings.LastServerForDeploy
$BindingsFileName=$serverSettings.BindingsFileName
$ServiceHostAccountName=$serverSettings.ServiceHostAccountName
$NtGroupName=$serverSettings.NtGroupName
$DRInstance=$serverSettings.DRInstance
$FirstServerInGroup=$serverSettings.FirstServerInGroup

$TargetServer=$DatabaseName

if (test-path 'BizTalk:')
{
    Remove-PSDrive -Name BizTalk
}

New-PSDrive -Name BizTalk -PSProvider BizTalk -Root BizTalk:\ -Instance $DatabaseName -Database BizTalkMgmtDb >$null

