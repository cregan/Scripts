########################################################################################
#	Software Script Header t
#	Version of Software Script
#	Author:		Matt Soteros
#	Version:	v1.1
########################################################################################
#   Variables
########################################################################################
Set-Location c:\
# Set base path to prefix all installation paths.
$sPath = "C:\Admin\Software"
# Get Computer Name  this will be used for Licensing infomation
$sComputerName = $env:COMPUTERNAME
# Set The Log Location
$sFile = "C:\Admin\SoftwareInstallation.TXT"
# Set base bath for Registry uninstallation Paths
$rPathX64 = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
$rPathX86 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$sComputerModel = (Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem").Model
$sComputerMake = (Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem").Manufacturer
$sChassisType = (Get-WmiObject -Query "SELECT * FROM Win32_SystemEnclosure").ChassisTypes
$oProcess = New-Object system.Diagnostics.Process
$oProcStartInfo = New-Object System.Diagnostics.ProcessStartInfo

########################################################################################
#   Functions
########################################################################################
Function WriteToLog($sMessage)
#Writes to Log file in the following format: 01/01/2013 01:00:00 : Update...
{ 
    $sDate = Get-Date -Format "MM/dd/yyyy"
    $sTime = Get-Date -Format "hh:mm:ss"
    $tMessage = "$sDate $sTime : $sMessage"
    $tMessage | Out-File -FilePath $sLogLocation -Append
}
Function startProcess ($aStartInfo, $sFileCheckPath)
{
	WriteToLog "Attempting to install" $aStartInfo.FileName $aStartInfo.Arguments
	WriteToLog "Using $sFileCheckPath for installation verification."
	$oProcess.StartInfo = $oProcStartInfo
	#$oProcess.Start()
	#$oProcess.WaitForExit()
	WriteToLog "Install has returned to command shell."
	#Loop Script with included sleep and file check
	If (!(Test-Path $sFileCheckPath -eq ""))
	{
		For($i=1; $i -le 46; $i++)
		{
			If (Test-Path $sFileCheckPath) #If Checkfile is found For Loop will break
			{
			WriteToLog "Install is complete and file verified"; break}
			Start-Sleep -Seconds 60 #Check for completion of install every minute
			}
			If ($i -eq 45) {WriteToLog "Install did not complete in the alloted 45 minute time period."; Restart-Computer}
		}
	}
}
########################################################################################
#   Software Installation
########################################################################################
#Start a fresh SOFTWARE log file
Out-File -FilePath $sLogLocation "Software script has begun." -Force
#Stop Symantec AV from running while installing Software
$SMC = Get-Process smc -erroraction silentlycontinue
If($SMC -ne $null)
{
	$oProcStartInfo.FileName = 'C:\Program Files (x86)\Symantec\Symantec Endpoint Protection\12.1.2015.2015.105\Bin64\Smc.exe'
    $oProcStartInfo.Arguments = "-stop"
    startProcess $oProcStartInfo
}

#SQL Server 2008 R2
$sCheckPath = "$rPathX64\{3A9FC03D-C685-4831-94CF-4EDFD3749497}"
If (!(Test-Path -Path $sCheckPath))
{
	$oProcStartInfo.FileName = $sPath + "\smartcop\SQL2008R2\X64\SQLEXPRWT_x64_ENU.exe"
	$oProcStartInfo.Arguments = "/Q /SAPWD=`$m@rtc0p /ConfigurationFile=C:\Admin\Software\smartcop\SQL2008R2\X64\ConfigurationFile.ini"
	startProcess $oProcStartInfo $sCheckPath
}

#Mobile Forms
$sCheckPath = "$rPathX64\{3A9FC03D-C685-4831-94CF-4EDFD3749497}"
If (!(Test-Path -Path $sCheckPath))
{
	$oProcStartInfo.FileName = $sPath + "\smartcop\RMS_8_4_19.msi"
	$oProcStartInfo.Arguments = "/qb IS_SQLSERVER_USERNAME=sa IS_SQLSERVER_PASSWORD=`$m@rtc0p /l* c:\admin\Mobileforms.txt"
	startProcess $oProcStartInfo $sCheckPath
}

#SmartCop
$sCheckPath = "$rPathX64\{10BE7BF8-01C3-4FF5-AE39-6DA125C68EE7}"
If (!(Test-Path -Path $sCheckPath))
{
	$oProcStartInfo.FileName = $sPath + "\SmartCop\MCT_8_2_13.msi"
	$oProcStartInfo.Arguments = "/qb IS_SQLSERVER_USERNAME=sa IS_SQLSERVER_PASSWORD=`$m@rtc0p /l* c:\admin\SmartCop.txt"
	startProcess $oProcStartInfo $sCheckPath
}

# Looks to see if it is a laptop/Notebook/Portable/ HandHend then install Netmotion, Imprivata, etc....
If (($sChassisType -eq '8') -or ($sChassisType -eq '9') -or ($sChassisType -eq '10') -or ($sChassisType -eq '11'))
	{Laptop} else {break}
#ChassisType 8 = Portable
#ChassisType 9 = Laptop
#ChassisType 10 = NoteBook
#ChassisType 11 = HandHeld