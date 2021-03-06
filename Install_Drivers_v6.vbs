'==========================================================================
'
' NAME: Install_Drivers_v4.vbs
'
' AUTHOR: Brian Gonzalez, PSCNA
' DATE  : 10/9/2012
'
' COMMENT: 
'==========================================================================
'On Error Resume Next
'Setup common objects
Const ForReading = 1, ForWriting = 2, ForAppending = 8
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")
Set objNetwork = CreateObject("Wscript.Network")

'Populate var with current directory
strScriptFolder = objFSO.GetParentFolderName(Wscript.ScriptFullName) 'No trailing backslash
strLogFilePath = "C:\Windows\Temp\Pana_Install_Drivers.log"
strTempFolder = objShell.ExpandEnvironmentStrings("%Temp%")
objShell.CurrentDirectory = strScriptFolder

'Ensure script is being run locally
strQuery = "SELECT * FROM Win32_LogicalDisk WHERE DeviceID LIKE '" & Left(strScriptFolder, 2) & "'"
'Run query against Drive Letter pulled from strScriptFolder var
Set objWMIService = GetObject("winmgmts:\\.\root\CIMV2")
Set colItems = objWMIService.ExecQuery(strQuery, "WQL", _
	wbemFlagReturnImmediately + wbemFlagForwardOnly)
For Each objItem In colItems
   strDiskDescription = objItem.Description
Next

'Check if Drive Letter is a local fixed disk and not a mapped drive
If Not strDiskDescription = "Local Fixed Disk" Then
	logHelper "Script needs to be run locally, so copy routine is beginning..."
	Wscript.Echo "Script needs to be run locally, so copy routine is beginning..."
	'objFSO.CopyFolder strScriptFolder, "C:\Drivers", True
	'intReturn = objShell.Run("cmd /k " & strrcPath & " /S /E /DCOPY:DA /COPY:DAT /PURGE /MIR /R:5 /W:5 """ & strScriptFolder & """ ""C:\Drivers"" /XF ""99_*""")
	sCmd = "cmd /c xcopy """ & strScriptFolder & """ C:\Drivers\ /heyi"
	intReturn = objShell.Run(sCmd, 3, True)
	If Not intReturn = 0 Then
		logHelper "Copy was unsuccessful, exiting script."
		Wscript.Echo "Copy was unsuccessful, exiting script."
		WScript.Quit
	End If
	logHelper "Copy is complete, now kicking off copied script (C:\Drivers\Install_Drivers.vbs)..."
	Wscript.Echo "Copy is complete, now kicking off copied script (C:\Drivers\Install_Drivers.vbs)..."
	sRet = objShell.Run("cscript.exe //NoLogo C:\Drivers\" & Wscript.ScriptName, 3, True)
	WScript.Quit
End If
'////Main Execution/////
'=====================================================
'Enumerate through the src subfolder
strDriverParentFolder = strScriptFolder & "\src"
If objFSO.FolderExists(strDriverParentFolder) Then

	'Set up object for driver folder to utilize SubFolders collection attrib
	Set objDriverParentFolder = objFSO.GetFolder(strDriverParentFolder)
	'Cycle through .ZIP files, extract and delete them using 7zip
	For Each fil In objDriverParentFolder.Files
		If Right(fil.name, 3) = "zip" Then
			strCmd = "cmd /c 7za.exe x ""src\" & fil.name & """ -o""src\*"" -y" 
			WScript.Echo "Extracing archive: " & fil.path
			logHelper "Extracing archive: " & fil.path
			intReturn = objShell.Run(strCmd, 3, True)
			If intReturn = 0 Then
				objFSO.DeleteFile fil.path
			Else
				WScript.Echo "Error when extracting archive, may be corrupt: " & fil.path & ", exiting script"
				logHelper "Error when extracting archive, may be corrupt: " & fil.path & ", exiting script"
				WScript.Quit
			End If
		Else
			WScript.Echo fil.name  & " is not a valid archive."
			logHelper fil.name  & " is not a valid archive."
		End If
	Next
	
	'Cycle through sub-folders and execute "PInstall.bat" files within directories, if avail.
	For Each fol In objDriverParentFolder.SubFolders
		'Ignore "99" pre-fixed directories as they are predetermined as optional
		If Not Left(fol.name, 2) = "99" Then
			
			strPNPIDTxtPath = fol.path & "\pnpid.txt"
			PNPIDMismatch = ""
			If objFSO.FileExists(strPNPIDTxtPath) Then
				'PNPID text file found, reading file
				Set objPNPIDTxtFile = objFSO.OpenTextFile(strPNPIDTxtPath)
				strpnpid = objPNPIDTxtFile.ReadAll
				logHelper "PNPID file found for: " & strpnpid
				If PNPMatch(strpnpid) = 0 Then 'No matches found
					logHelper "PNPID NOT found in WMI database"
					PNPIDMismatch = True
				End If
			End If
			
			strPInstallPath = fol.path & "\pinstall.bat"
			'Check if "PInstall.bat" file inside subfolder exists.
			If objFSO.FileExists(strPInstallPath) And Not PNPIDMismatch = True Then
				'It does exist, so set "CurrentDirectory" to driver folder
				objShell.CurrentDirectory = fol.path
				logHelper "Executing: " & fol.path & "\pinstall.bat"
				Wscript.Echo "Executing: " & fol.path & "\pinstall.bat"
				sRet = objShell.Run("cmd /c pinstall.bat", 2, True)
				logHelper "Completed executing and returned: " & sRet
			End If
		Else
			logHelper "Ignoring install: " & fol.path
			Wscript.Echo "Ignoring install: " & fol.path
		End If
	Next

Else
	'No src folder exists
	loghelper "Utility and driver folder does not exist (""" & strDriverParentFolder & """) .  Exiting Script."
	WScript.Quit
End If
loghelper "Image configuration is complete."


Sub logHelper(strText)
	If Not IsObject(objLogFile) Then
		Set objLogFile = objFSO.OpenTextFile(strLogFilePath, ForAppending, True)
	End If
	objLogFile.WriteLine(Time & ": " & strText)
End Sub

Function PNPMatch(strPNPDeviceID)
	Set objWMIService = GetObject("winmgmts:\\.\root\CIMV2")
	Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_PnPEntity WHERE PNPDeviceID LIKE '%" & strPNPDeviceID & "%'")
	PNPMatch = colItems.Count
End Function
