function pause {
    Write-Host 'Press any key to continue...';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}
Function FileNotFound {
    Write-Host ""
    Write-Host "A file was missing! Check if it exists and try again."
    pause
    break
}
$console = $host.ui.rawui
$global:Version = "1.4.2"
$console.backgroundcolor = "black"
Clear-Host
# Gather command meta data from the original Cmdlet (in this case, Test-Path)
$TestPathCmd = Get-Command Test-Path
$TestPathCmdMetaData = New-Object System.Management.Automation.CommandMetadata $TestPathCmd

# Use the static ProxyCommand.GetParamBlock method to copy 
# Test-Path's param block and CmdletBinding attribute
$Binding = [System.Management.Automation.ProxyCommand]::GetCmdletBindingAttribute($TestPathCmdMetaData)
$Params = [System.Management.Automation.ProxyCommand]::GetParamBlock($TestPathCmdMetaData)

# Create wrapper for the command that proxies the parameters to Test-Path 
# using @PSBoundParameters, and negates any output with -not
$WrappedCommand = { 
    try { -not (Test-Path @PSBoundParameters) } catch { throw $_ }
}

# define your new function using the details above
$Function:notexists = '{0}param({1}) {2}' -f $Binding, $Params, $WrappedCommand
Clear-Host
Write-Host "Checking..." -ForegroundColor Yellow
if ($PSVersionTable.PSVersion.Major -ge 5) {
    Write-Host "PowerShell version:" $PSVersionTable.PSVersion
}
else {
    Write-Host "QTools requires at least PowerShell 5. Please update!"
    pause
    Break
}

If ($(Get-WmiObject -class Win32_OperatingSystem).Caption -contains "Windows 10" -or "Server 2016") {
    Write-Host "Windows version:" (Get-WmiObject -class Win32_OperatingSystem).Caption
    }

else {
    Write-Host "Your Windows version is not compatible, use Windows 10 or Server 2016.:"
    Break
}
#Setup
Set-Location $PSScriptRoot
Write-Host ""
#User greeting
Write-Host "==================================================" -ForegroundColor Green
Write-Host "QTools scripted utilities and cleaner for Windows." -ForegroundColor Green
Write-Host "Release $Version" -ForegroundColor Green
Write-Host "Last update:" (gci . | sort LastWriteTime | select -last 1).LastWriteTime
Write-Host "==================================================" -ForegroundColor Green

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {    
    Echo "This script needs to be run As Admin"
    pause
    if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
            $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
            Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "-ExecutionPolicy Bypass $CommandLine"
            Exit
        }
    }
}

#File checks 
Write-Host "Checking files..."
if (!(notexists -Path ".\qTools.ps1")) {
    Write-Host "Kickstarter script found" -ForegroundColor Green
}
else {
    Write-Host "Kickstarter script is missing! " -ForegroundColor Red
    FileNotFound
}
if (!(notexists -Path ".\Scripts\Warning.ps1")) {
    Write-Host "Warning script found" -ForegroundColor Green
}
else {
    Write-Host "Warning script is missing!" -ForegroundColor Red
    FileNotFound
}
if (!(notexists -Path ".\Scripts\BleachBit.ps1")) {
    Write-Host "BleachBit script found" -ForegroundColor Green
}
else {
    Write-Host "BleachBit script is missing!" -ForegroundColor Red
    FileNotFound
}
if (!(notexists -Path ".\Scripts\UltraDefrag.ps1")) {
    Write-Host "UltraDefrag script found" -ForegroundColor Green
}
else {
    Write-Host "UltraDefrag script is missing!" -ForegroundColor Red
    FileNotFound
}
if (!(notexists -Path ".\Scripts\Menu.ps1")) {
    Write-Host "Menu script found" -ForegroundColor Green
}
else {
    Write-Host "Menu script is missing!" -ForegroundColor Red
    FileNotFound
}
if (!(notexists -Path ".\Scripts\Windows_Cleanup.ps1")) {
    Write-Host "Cleaner script found" -ForegroundColor Green
}
else {
    Write-Host "Cleaner script missing!" -ForegroundColor Red
    FileNotFound
}

if (!(notexists -Path ".\Data\SU10-Default.cfg") -And (!(notexists -Path ".\Data\SU10-QS.cfg")) -And (!(notexists -Path ".\Data\SU10-Recommended.cfg") -and (!(notexists -Path ".\Scripts\ShutUp10.ps1")))) {
    Write-Host "ShutUp10 data is present."
}
else {
    Write-Host "ShutUp10 is missing some data! Check the script and CFG files, there should be 4 in total."
    FileNotFound
}


#Warn the user about the script
Write-Host "" 
.\Scripts\Warning.ps1
Write-Host ""
pause
#Launch the main menu
Write-Host "Launching menu..." -ForegroundColor Red

.\Scripts\Menu.ps1
Write-Host ""
Write-Host "==================================" -ForegroundColor Green
Write-Host "Thank you for using QTools!" -ForegroundColor Green
Write-Host "Release $Version" -ForegroundColor Green
Write-Host "Last update:" (gci . | sort LastWriteTime | select -last 1).LastWriteTime
Write-Host "==================================" -ForegroundColor Green
pause