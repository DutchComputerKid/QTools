Add-Type -AssemblyName System.IO.Compression.FileSystem

function pause {
    Write-Host 'Press any key to continue...';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

function AskForConsoleArgs {
    # param(
    #[Parameter(Mandatory)]
    #[string]$Name
    #)
    Write-Host ""
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes', 'Allows for manual command like switches'
    $no = New-Object System.Management.Automation.Host.ChoiceDescription '&No', 'Runs vanilla'
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $result = $host.ui.PromptForChoice('Arguments?', 'Enter arguments manually?', $options, 0)
    Write-Host "You can now enter your desired switches. For more help on these switches, visit https://www.bleachbit.org" -ForegroundColor Yellow

    switch ($result) {
        0 {
            $global:Arguments = Read-Host -Prompt 'Enter your arguments now:'
            $message = "BleachBit_console will be run with: " + $Arguments
        }
        1 {
            $message = "Running vanilla."
        }
    }
    Write-Output $message
}

function ModeSelection {
    Write-Host "Now come a series of questions regarding what you want to do."  -foreground yellow
    Write-Host "BleachBit comes with a console and a Graphical (GUI) version. The GUI is easy to use, the command line needs some input from you." -foreground yellow
    $choice = ""
    while ($choice -notmatch "[c|g]") {
        $choice = read-host "Console or GUI? (C/G)"
    }

    if ($choice -eq "g") {
        $global:CommandLineOptions = "GUI"
        Write-Host "Mode set to GUI." -ForegroundColor Red
    }
    if ($choice -eq "c") {
        $global:CommandLineOptions = "CON"
        Write-Host "Mode set to CONSOLE." -ForegroundColor Red
    }
   
    #else {write-host "Something went wrong, try again."
    #if($CommandLineOptions -notcontains "[c|g]"){ModeSelection}}
    # Above commands crash the system for some reason
}

function BleachDownload {
    Write-Host "You answered YES, please wait."
    Write-host "Downloading BleachBit 2.0..." -ForegroundColor yellow
    $url = "https://download.bleachbit.org/BleachBit-2.0-portable.zip"
    $output = ".\Data\BleachBit.zip"
    $start_time = Get-Date

    Import-Module BitsTransfer
    Start-BitsTransfer -Source $url -Destination $output
    #OR -Asynchronous

    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
    Write-Host "Looking for and removing TMP files..."
    get-childitem ".\" -recurse -force -include *.TMP| remove-item -force
}

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", ""
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", ""
$choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$caption = "Hello!"
Write-Host "This script will help you download and run BleachBit." -foreground yellow
Write-Host "BleachBit is a free and open-source disk space cleaner, privacy manager, and computer system optimizer." -foreground yellow
$message = "Download BleachBit?"
$result = $Host.UI.PromptForChoice($caption, $message, $choices, 0)
if ($result -eq 0) { 
    try {
        BleachDownload
    }
    catch {
        write-host "Caught an exception:" -ForegroundColor Red
        write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
        write-host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red

    }
    finally {
        write-host "Complete!" -foreground green
    }
}
if ($result -eq 1) { 
    Write-Host "You answered NO, Exiting..." 
    exit
}
Write-Host ""
Write-Host "Checking file integrity" -ForegroundColor yellow
[Environment]::CurrentDirectory = $PWD
Pop-Location
[Environment]::CurrentDirectory = $PWD

$ExpectedHash = "F704477FC9D25ACB907399322033F141BF5B36B056FE3ABA2463154CCF60EA63"
$hash = (Get-FileHash .\data\BleachBit.zip -Algorithm SHA256).Hash
Write-Host "Current file hash: " $hash
Write-host "Expected file hash: " $ExpectedHash
if ($hash -contains "F704477FC9D25ACB907399322033F141BF5B36B056FE3ABA2463154CCF60EA63") {
    write-host "File OK." -ForegroundColor green
}
Write-Host ""
Write-Host "Unzipping BleachBit..."
$TARGETDIR = ".\Data\BleachBit-Portable"
if (!(Test-Path -Path $TARGETDIR )) {
    New-Item -ItemType directory -Path $TARGETDIR | Out-Null
}
Expand-Archive ".\Data\BleachBit.zip" ".\Data\" -Force
if (!(Test-Path -Path ".\Data\BleachBit-Portable\bleachbit_console.exe")) {
  
    Write-Host "Something went wrong." -ForegroundColor red
}
else {
    Write-Host "Extraction complete!" -ForegroundColor Green 
}
pause


# BleachBit questioning portion.
ModeSelection
#If($CommandLineOptions=""){$CommandLineOptions="GUI"}
#Write-Debug "Current selection: " $CommandLineOptions
if ($CommandLineOptions -contains "CON") {
    $global:Arguments = ""
    Write-Host "Console mode. You may now enter extra options: "
    AskForConsoleArgs
    Write-Host " Executing..." -ForegroundColor Green
    if ($Arguments -eq "") {
        Write-Host "Oopsie, we cannot run the console version without arguments, instead, run the GUI!" -ForegroundColor Red
    }
    else {
        Start-Process -FilePath ".\data\BleachBit-Portable\bleachbit_console.exe" -ArgumentList "$Arguments" -WindowStyle Normal -Wait
    }
    pause
}
if ($CommandLineOptions -contains "GUI") {
    Write-Host "GUI mode, we will launch immidiately."
    Start-Process -FilePath ".\Data\BleachBit-Portable\bleachbit.exe" -WindowStyle Normal -Wait
}
Write-Host "BleachBit process ended." -ForegroundColor Green



Write-Host "Cleaning up and removing temporary data..."
Remove-Item -Recurse ".\Data\BleachBit-Portable"
Remove-Item -Recurse ".\Data\BleachBit.zip"
write-host "Script Complete!" -ForegroundColor Green
pause