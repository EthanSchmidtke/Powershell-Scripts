# What this needs to do:
# 1. DONE - Run at startup | Create a batch script to put in the startup folder that runs this script under the C: drive
# 2. DONE - Check for a physical network connection every 30 minutes
# 3. DONE - If no connection is detected for 2 straight minutes, reset the network adapter
# 4. DONE - If no connection detected still after 2 minutes, restart the computer
# 5. Rinse and repeat until connection is detected or until process has been done 5 times without success
# 6. After 5 attempts, all failing, leave a prompt on screen stating the issue

Start-Transcript -OutputDirectory "C:\" -Append -Force

$i = 0

function Get-NetworkStatus {

    $status = Get-NetConnectionProfile -Name "amd.com"
    $wifi = Get-NetAdapter -Name "Wi-Fi*"

    switch ($wifi.Status) {

        "Up" {

            Write-Host "System connected via WiFi"
            Write-Host "Disabling WiFi"
            Disable-NetAdapter -Name $wifi.Name

        }

        "Disconnected" {

            Write-Host "WiFi is disconnected, skipping"
            Break

        }

    }

    switch ($status.IPv4Connectivity) {

        "Internet" {
    
            Write-Host "Physical network connection found. Checking again in 30 minutes."
            Start-Sleep -Seconds 1800
            Get-NetworkStatus
    
        }
    
        "NoTraffic" {
    
            if ($i -eq 1) {

                Write-Host "Resetting network adapter"
                $i++
                Restart-NetAdapter -Name $status.InterfaceAlias
                Start-Sleep -Seconds 120
                Get-NetworkStatus

            } elseif ($i -eq 2) {
                
                Write-Host "Network adapter reset did not resolve issue. Restarting computer."
                Start-Sleep -Seconds 5
                Restart-Computer -Force
                Start-Sleep -Seconds 60
                Write-Host "Restart may have failed. Attempting again."
                Restart-Computer -Force
                Start-Sleep -Seconds 60
                EXIT

            }

            Write-Host "No physical network connection established. Checking again in 2 minutes."
            $i++
            Start-Sleep -Seconds 120
            Get-NetworkStatus
    
        }
    
        Default {
    
            Write-Host "Reported IPv4 Connectivity status ($_) not known. Checking again in 2 minutes."
            Start-Sleep -Seconds 120
            Get-NetworkStatus
    
        }
    
    }
    
}

Get-NetworkStatus