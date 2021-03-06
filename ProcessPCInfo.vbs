'==========================================================================
'
' NAME: ProcessPCInfo.vbs
'
' AUTHOR: Brian Gonzalez, PSCNA
' DATE  : 2/13/2013
'
' COMMENT: Parse PC Info Logs and prep to add data for BaseComparator
'==========================================================================
Set oFSO = CreateObject("Scripting.FileSystemObject")
Set oShell = CreateObject("WScript.Shell")
Set oNetwork = CreateObject("Wscript.Network")
sScriptFolder = oFSO.GetParentFolderName(Wscript.ScriptFullName) 'No trailing backslash

Set oScriptFolder = oFSO.GetFolder(sScriptFolder)
Set aOrigLogs = oScriptFolder.Files
For Each oLog In aOrigLogs
	If Right(oLog.Name, 3) = "TXT" Then
	
		sOrigLogPath = oLog.Path
		sNewFileName = sScriptFolder & "\" & "New-" & Left(oLog.Name, (Len(oLog.Name) - 3)) & ".csv"
		Set oOrigLog = oFSO.OpenTextFile(sOrigLogPath)
		Set oNewLog = oFSO.CreateTextFile(sNewFileName, True)
		
		Do Until oOrigLog.AtEndOfStream
			sNewLine = oOrigLog.ReadLine
			For i = 1 To 20
				sNewLine = Replace(sNewLine,"  "," ")
			Next
		
			Set oRE = New RegExp
			With oRE
			    .Pattern    = "\s(?=(\d|V\d)(\d|\.)(\d|\.)(\d|\.)+)"
			    .IgnoreCase = True
			    .Global     = True
			End With
			sNewLine = oRE.Replace(sNewLine,",")
			sNewLine = Replace(sNewLine, ":", ",")
			oNewLog.WriteLine(sNewLine)
		Loop
	
	End If
Next
