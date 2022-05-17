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

    if ($NULL -eq $status) {

        Write-Host "No connection to the amd.com network detected by either WiFi or Ethernet"
        Write-Host "Disabling Power Management for USB Root Hub devices and restarting system"

        # Disabling the two USB Root Hub's power saving feature did not resolve the issue on
        #my Lenovo T16 - Disabling power saving for ALL devices under 'Universal Serial Bus Controllers'
        #in Device Manager to see if that resovles it. If it does, need to update script to accomodate it.
        # Disabling power saving for all other devies under 'Universal Serial Bus Controllers' did not
        #resolve the issue either. There are two devices, 'USB4 Root Device Router', that will not
        #retain the changes made to them after a reboot. Meaning disabling their power saving
        #setting does not work. These could be responsible though I am not sure.
        # I disabled the power saving feature directly for the USB ethernet adapter driver under
        #'Network Devices'. I don't expect this to work but it may just.
        $hubs = Get-WmiObject Win32_USBHub
        $powerMgmt = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi
        foreach ($p in $powerMgmt) {

            $IN = $p.InstanceName.ToUpper()
            foreach ($h in $hubs) {

                $PNPDI = $h.PNPDeviceID
                if ($IN -like "*$PNPDI*") {

                    if ($p.enable -eq $False) {

                        Write-Host "Power saving already disabled on USB Root Hub, script failed to fix issue."
                        EXIT

                    } elseif ($p.enable -eq $True) {

                        Write-Host "Disabling power saving on USB Root Hub"
                        $p.enable = $False
                        $p.psbase.put()

                    }

                }

            }

        }

        Start-Sleep -Seconds 1
        Restart-Computer -Force

    }

    $wifi = Get-NetAdapter -Name "Wi-Fi*"

    switch ($wifi.Status) {

        "Up" {

            Write-Host "System connected via WiFi"
            Write-Host "Disabling WiFi"
            Disable-NetAdapter -Name $wifi.Name
            Start-Sleep -Seconds 10

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

Write-Host "Giving Windows 60 seconds to 'situate' network devices"
Start-Sleep -Seconds 60

Get-NetworkStatus