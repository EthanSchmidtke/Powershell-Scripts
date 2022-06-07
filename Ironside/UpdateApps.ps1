<#
NEW - Goals

(x) Open Windows store
(x) Select 'Check For Updates'
(x) Find a way programmatically to check status of updates
(x) Select 'Check For Updates' until no further updates are available

In the future, I may be able to use Get-AppxPackageAutoUpdateSettings

#>

Add-Type -AssemblyName System.Windows.Forms

function Get-MSStoreUpdates {

    [System.Collections.ArrayList]$appsPreUpdate = Get-AppxPackage -AllUsers
    Write-Host "Checking for Microsoft Store app updates"
    Start-Process ms-windows-store://downloadsandupdates
    Start-Sleep -Seconds 10
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Seconds 300
    [System.Collections.ArrayList]$appsPostUpdate = Get-AppxPackage -AllUsers

    Write-Host "Checked for updates 5 minutes ago. Checking results."
    Get-PendingUpdates
    
}

function Get-PendingUpdates {

    switch ($appsPostUpdate.Count -gt $appsPreUpdate.Count) {

        "True" {

            Write-Host "More apps have been added to the system. Checking for updates again in 5 minutes."
            Start-Sleep -Seconds 300
            Get-MSStoreUpdates

        }

        "False" {

            Write-Host "No new apps have been added to the system. Checking app version numbers."
            $count = 0
            $updatesPending = 0
            $appsPostUpdate | ForEach-Object {

                if ($_.Version -gt $appsPreUpdate[$count].Version) {
                    Write-Host $_.Name "updated from version" $appsPreUpdate[$count].Version "to version" $_.Version
                    $updatesPending++
                } else {
                    Write-Host $_.Name "did not update"
                }
                $count++

            }

            switch ($updatesPending) {

                "0" {

                    Write-Host "No apps updated. Exiting store and script."
                    Stop-Process -Name WinStore.App -Force
                    EXIT 0

                }

                Default {

                    Write-Host $updatesPending "apps updated. Checking for additional updates in 5 minutes."
                    Start-Sleep -Seconds 300
                    Get-MSStoreUpdates

                }

            }

        }

    }
    
}

Get-MSStoreUpdates