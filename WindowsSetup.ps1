#Windows setup script

#Opens the Windows update screen - This 'should' run the 'Check For Updates' button, although I'm unsure currently
Explorer MS-Settings:WindowsUpdate-Action

PAUSE

#This appears to be an older means of checking for Windows updates - No idea if it works, might only work with a WSUS server
wuauclt

PAUSE

#The use of Winget is meant to automate the process of updating all Windows Store apps. I don't believe it will update
#'everything' like the Windows store does, but any automation is better than none.
#The command does not like --force --accept-package-agreements
Winget upgrade --silent --accept-source-agreements --all --include-unknown

#Opens the Windows Store to the homepage - Not sure how to open to the library currently but this could still be
#automated by using SENDKEYS
ms-windows-store:

#This snippet will run the 'Check For Updates' button in the Windows Store
Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod
 -MethodName UpdateScanMethod