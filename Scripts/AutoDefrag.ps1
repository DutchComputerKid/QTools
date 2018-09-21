function pause {
    Write-Host 'Press any key to continue...';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

function NotInstalled {
    Write-Host "" 
    Write-Host "Oopsie, it seems you don't have UltraDefrag installed! You can install it right from the previous menu." -ForegroundColor Gray
    pause
    break
}

function NoneSelected {
    Write-Host ""
    Write-Host "No selections were made, try again!" -ForegroundColor Gray
    pause
    break
}

Write-Host "Now come a series of questions regarding what you want to do."  -foreground yellow
Write-Host "If you have installed UltraDefrag and which to run a series of defragmentation sessions on selected drives, this script is for you." -foreground yellow
Write-Host "This will pop up a GUI where you can select the drives, defragmentation type, and that's it, it's that simple." -ForegroundColor Yellow
$choice = ""
while ($choice -notmatch "[y|n]") {
    $choice = read-host "Continue? (Y/N)"
}
if ($choice -eq "n") {
    exit
}
if ($choice -eq "y") {
    Write-Host ""
}


Write-Host "Reading installed software and checking for UltraDefrag..." -NoNewline
$installedsoftware = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*  | Select-Object DisplayName | Format-Table –AutoSize
if ($installedsoftware -contains "Ultra Defragmenter" -or "UltraDefrag") {
    Write-Host "Detected" -ForegroundColor Green
}
else {NotInstalled}

Write-Host "Okay great! Now, you have a couple of options:"
Write-Host "- Defragmentation: Makes all fragmented files nice and tidy." -ForegroundColor White
Write-Host "- Quick Optimization: Grabs the most important data and puts it tighty together for increased speed." -ForegroundColor White
Write-Host "- Full Optimization: Grabs all data on your drive and condenses it for maximum speed." -ForegroundColor White

$choice = ""
while ($choice -notmatch "[d|q|f]") {
    $choice = read-host "(D)efragment, (Q)uick Optimization or (F)ull Optimization?"
}
if ($choice -eq "d") {
    $Global:type = "-d"
}
if ($choice -eq "q") {
    $Global:type = "-q"
}
if ($choice -eq "f") {
    $Global:type = "-o"
}
Write-Host ""
Write-Host "Okay last question, it is sometimes recommended to run multiple sessions. This can increase performance even more but will take longer." -ForegroundColor White
Write-Host "Also, if the recommended amount of runs has passed, UltraDefrag will automatically ignore the others."
$choice = ""
while ($choice -notmatch "[y|n]") {
    $choice = read-host "Yes or No? (Y/N)"
}
if ($choice -eq "y") {
    $global:rerun = Read-Host -Prompt 'Enter your amount of sessions now'
    $Global:rerun = "-r" + $global:rerun 
}
if ($choice -eq "n") {
    $Global:rerun = ""
}
Write-Host ""
Write-host "Please wait & select your desired drives. Multiple selections are possible." -foreground yellow
Write-Host "Keep in mind, defragmenting SSD's is " -NoNewline 
Write-Host "BAD" -ForegroundColor Red -NoNewline 
Write-Host " so only select true hard disks."
$SelectedVolumes = Get-Volume| OGV  -PassThru -Title "Select your disks" | Select -Property DriveLetter
Write-Host "Your selected disks are:" $SelectedVolumes.DriveLetter
# Insert user confirmation.
$SelectedDriveLetters = $SelectedVolumes.DriveLetter -split "\s+"
#write-host $StateRun, $SelectedVolumes, $SelectedDriveLetters
if ($SelectedDriveLetters -contains "") {NoneSelected}
Measure-Command {
    $SelectedDriveLetters | ForEach-Object { 
        $_ = $_ + ":"
        Write-Host "Running for: $_" 
        Start-Process -FilePath udefrag.exe -ArgumentList "$global:type $_ -m --use-entire-window --wait"  -WindowStyle Normal -Wait}}
Write-Host "Process(es) complete!" -ForegroundColor Green
pause
