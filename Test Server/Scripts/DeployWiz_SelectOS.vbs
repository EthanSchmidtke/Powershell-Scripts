' // ***************************************************************************
' //
' // File:      DeployWiz_SelectOS.vbs
' //
' // Version:   1.0.0000.0000
' //
' // Purpose:   Script used for selecting desktop background
' //
' // Author: 	Ethan "Your Mom" Schmidtke
' //
' // ***************************************************************************



Function SetOS
Set oOS = document.getElementsByName("OS")
	
	strOS = ""
	strOS = strOS & (Property("OS")) & vbCrLf

	oEnvironment.Item("OS") = strOS
	
End Function