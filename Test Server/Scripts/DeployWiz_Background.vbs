' // ***************************************************************************
' //
' // File:      DeployWiz_Background.vbs
' //
' // Version:   1.0.0000.0000
' //
' // Purpose:   Script used for selecting desktop background
' //
' // Author: 	Ethan "Your Mom" Schmidtke
' //
' // ***************************************************************************



Function SetBackground
	Set oBackgrounds = document.getElementsByName("Background")
	
	strBackground = ""
	strBackground = strBackground & (Property("Background")) & vbCrLf

	oEnvironment.Item("Background") = strBackground

End Function