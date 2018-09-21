Add-Type -AssemblyName System.IO.Compression.FileSystem

function pause {
    Write-Host 'Press any key to continue...';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

Function FileNotFound {
    Write-Host ""
    Write-Host "A file was missing or invalid! Check if it exists and try again."
    Write-Host "If the matter is hash related and you are sure the file is authentic, you can update it yourself."
    Write-Host "Or send an email to quintus@quinsoft.nl and we will update qTools."
    pause
    break
}

function AskForConsoleArgs {
    # param(
    #[Parameter(Mandatory)]
    #[string]$Name
    #)
    Write-Host "We currently have these available:"
    Write-Host "- Recommended: This will set up all recommended settings and disable telemetry as much as possible." -ForegroundColor White
    Write-Host "- QS: This will set up your system to not only remove telemetry but other annoyances as well." -ForegroundColor White
    Write-Host "- Default: To reset all settings and start anew." -ForegroundColor White
    Write-Host "Which will it be? (d,r,q)"  -foreground yellow
    $choice = ""
    while ($choice -notmatch "[d|r|q]") {
        $choice = read-host "(R)ecommended, (Q)S or (D)efault?"
    }

    if ($choice -eq "r") {
        $global:ShutUpOptions = "R"
        Write-Host "Mode set to Recommended" -ForegroundColor Red
    }
    if ($choice -eq "q") {
        $global:ShutUpOptions = "Q"
        Write-Host "Mode set to QS" -ForegroundColor Red
    }
    if ($choice -eq "d") {
        $global:ShutUpOptions = "D"
        Write-Host "Mode set to Default" -ForegroundColor Red
    }
}

function ModeSelection {
    Write-Host "Now come a series of questions regarding what you want to do."  -foreground yellow
    Write-Host "We have bundled some pre-configured files for easy setup, if you wish to use them, choose console." -foreground yellow
    Write-Host "If you wish to set up everything youself, choose the GUI."
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

function ShutUpJustDownloadIt {
    Write-Host "You answered YES, please wait."
    Write-host "Downloading O&O ShutUp10" -ForegroundColor yellow
    $url = "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe"
    $output = ".\Data\ShutUp10.exe"
    $start_time = Get-Date

    Import-Module BitsTransfer
    Start-BitsTransfer -Source $url -Destination $output

    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
    Write-Host "Looking for and removing TMP files..."
    get-childitem ".\" -recurse -force -include *.TMP| remove-item -force
}

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", ""
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", ""
$choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$caption = "Hello!"
Write-Host "This script will help you download and run O&O ShutUp10." -foreground yellow
Write-Host "ShutUp10 is the go-to privacy manager for Windows 10" -foreground yellow
$message = "Download ShutUp10?"
$result = $Host.UI.PromptForChoice($caption, $message, $choices, 0)
if ($result -eq 0) { 
    try {
        ShutUpJustDownloadIt
    }
    catch {
        write-host "Caught an exception:" -ForegroundColor Red
        write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
        write-host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
        $global:ShutUpOptions = ""
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

$ExpectedHash = "1AB42ADF97F2AC1204CA85085C0D5B4FCB3D7FC70F9346D2E36BD5CB8070964C"
$hash = (Get-FileHash .\data\ShutUp10.exe -Algorithm SHA256).Hash
Write-Host "Current file hash:  " $hash
Write-host "Expected file hash: " $ExpectedHash
if ($hash -contains "1AB42ADF97F2AC1204CA85085C0D5B4FCB3D7FC70F9346D2E36BD5CB8070964C") {
    write-host "File OK." -ForegroundColor green
}
else {FileNotFound}


# BleachBit questioning portion.
ModeSelection
#If($CommandLineOptions=""){$CommandLineOptions="GUI"}
#Write-Debug "Current selection: " $CommandLineOptions
if ($CommandLineOptions -contains "CON") {
    Write-Host "Console mode. You may now enter extra options: "
    AskForConsoleArgs
    #$global:ShutUpOptions
    Write-Host " Executing, please wait..." -ForegroundColor Green
    if ($global:ShutUpOptions -eq "R") {
        #Write-Host "Launching & Setting up recommended mode..." -ForegroundColor Red
        Start-Process -FilePath ".\data\ShutUp10.exe" -ArgumentList ".\Data\SU10-Recommended.cfg /quiet /force" -WindowStyle Normal -Wait
    }
    if ($global:ShutUpOptions -eq "Q") {
        #Write-Host "Launching & Setting up QS mode" -ForegroundColor Red
        Start-Process -FilePath ".\data\ShutUp10.exe" -ArgumentList ".\Data\SU10-QS.cfg /quiet /force" -WindowStyle Normal -Wait
    }
    if ($global:ShutUpOptions -eq "D") {
        #Write-Host "Launching & Setting up Default mode..." -ForegroundColor Red
        Start-Process -FilePath ".\data\ShutUp10.exe" -ArgumentList ".\Data\SU10-Default.cfg /quiet /force" -WindowStyle Normal -Wait
    }
}
if ($CommandLineOptions -contains "GUI") {
    Write-Host "GUI mode, we will launch immidiately."
    Start-Process -FilePath ".\Data\ShutUp10.exe" -WindowStyle Normal -Wait
}
Write-Host "ShutUp process ended." -ForegroundColor Green
Write-Host "Remember! System reboot HIGHLY recommended to apply settings." -ForegroundColor Gray
Write-Host ""

Write-Host "Cleaning up and removing temporary data..."
Remove-Item -Recurse ".\Data\ShutUp10.exe" | Out-Null -ErrorAction SilentlyContinue
Remove-Item -Recurse ".\OOSU10.ini" | Out-Null -ErrorAction SilentlyContinue
write-host "Script Complete!" -ForegroundColor Green
pause