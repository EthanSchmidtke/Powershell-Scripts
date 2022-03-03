<#

.DESCRIPTION
ImageDefaults.ps1 sets the User image(s) to the Ironside logo and
the desktop wallpaper to the selected image from MDT.

#>

#Set our variables
$PicsDir = "D:\ProgramData\Microsoft\User Account Pictures\"
$ServerDir = "$TSEnv:DeployRoot\Scripts\Custom\ImageDefaults"

Try {

    #Sets the User's image
    Remove-Item "$PicsDir\guest.png" -Force
    Remove-Item "$PicsDir\user.png" -Force
    Remove-Item "$PicsDir\user-32.png" -Force
    Remove-Item "$PicsDir\user-40.png" -Force
    Remove-Item "$PicsDir\user-48.png" -Force
    Remove-Item "$PicsDir\user-192.png" -Force
    Copy-Item "$ServerDir\PicturesUser\guest.png" "$PicsDir" -Force
    Copy-Item "$ServerDir\PicturesUser\user.png" "$PicsDir" -Force
    Copy-Item "$ServerDir\PicturesUser\user-32.png" "$PicsDir" -Force
    Copy-Item "$ServerDir\PicturesUser\user-40.png" "$PicsDir" -Force
    Copy-Item "$ServerDir\PicturesUser\user-48.png" "$PicsDir" -Force
    Copy-Item "$ServerDir\PicturesUser\user-192.png" "$PicsDir" -Force

} Catch {

    #Throw will abort the Powershell script and spit out the string as an error.
    Throw "Aborted ImageDefaults.ps1, returned $_"

}

#Sets the default wallpaper
Remove-Item "D:\Windows\Web\4K" -Force
Rename-Item "D:\Windows\Web\Wallpaper\Windows\img0.jpg" "img1.jpg" -Force
Copy-Item "$ServerDir\PicturesWallpaper\$TSEnv:Wallpaper.jpg" "D:\Windows\Web\Wallpaper\Windows\img0.jpg" -Force