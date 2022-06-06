$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_EnterpriseModernAppManagement_AppManagement01"
$wmiObj = Get-WmiObject -Namespace $namespaceName -Class $className
$result = $wmiObj.UpdateScanMethod()

Write-Host "Sleeping while Store updates are processed"
Start-Sleep -Seconds 120

Get-Process -Name "WinStore.App", "RuntimeBroker", "Microsoft Store Background Task Host"

#Runs a second time for those pesky apps
$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_EnterpriseModernAppManagement_AppManagement01"
$wmiObj = Get-WmiObject -Namespace $namespaceName -Class $className
$result = $wmiObj.UpdateScanMethod()

Write-Host "Sleeping while Store updates are processed"
Start-Sleep -Seconds 120