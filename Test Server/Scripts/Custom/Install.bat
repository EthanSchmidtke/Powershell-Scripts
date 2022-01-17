SET Dir=C:\Applications\Install
"%Dir%\Superposition.exe" /SILENT /DIR=C:\Applications\Superposition
"%Dir%\BurnIn.exe" /SILENT /DIR=C:\Applications\BurnIn
"%Dir%\FurMark.exe" /SILENT /DIR=C:\Applications\FurMark
MOVE /Y "%Dir%\HWiNFO64" "C:\Applications"
MOVE /Y "%Dir%\Prime95" "C:\Applications"