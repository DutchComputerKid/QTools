# Written by Fabian Castagna
# Modified by QuinSoft
# Used as a complete windows cleanup tool
# FC: 15-7-2016
# QS: 15-9-2018
$ErrorActionPreference = "SilentlyContinue"
function Delete-ComputerRestorePoints {
    [CmdletBinding(SupportsShouldProcess = $True)]param(
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        $restorePoints
    )
    begin {
        $fullName = "SystemRestore.DeleteRestorePoint"
        #check if the type is already loaded
        $isLoaded = ([AppDomain]::CurrentDomain.GetAssemblies() | foreach {$_.GetTypes()} | where {$_.FullName -eq $fullName}) -ne $null
        if (!$isLoaded) {
            $SRClient = Add-Type -memberDefinition @"
[DllImport ("Srclient.dll")]
public static extern int SRRemoveRestorePoint (int index);
"@ -Name DeleteRestorePoint -NameSpace SystemRestore -PassThru
        }
    }
    process {
        foreach ($restorePoint in $restorePoints) {
            if ($PSCmdlet.ShouldProcess("$($restorePoint.Description)", "Deleting Restorepoint")) {
                [SystemRestore.DeleteRestorePoint]::SRRemoveRestorePoint($restorePoint.SequenceNumber)
            }
        }
    }
}
Write-host "Checking to make sure you have Local Admin rights" -foreground yellow
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    If (!($psISE)) {"Press any key to continue…"; [void][System.Console]::ReadKey($true)}
    Exit 1
}

Write-Host "Please hold on while we clean your system." -foreground green
Write-Host "You may see big walls of text here and there. This is normal as we'll be cleaning the event logs." -foreground green
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", ""
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", ""
$choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$caption = "Warning!"
$message = "Do you want to clear your System Restore Points?"
$result = $Host.UI.PromptForChoice($caption, $message, $choices, 1)
if ($result -eq 0) {
    Write-Host "You answered YES."
    Write-Host "Deleting System Restore Points" -foreground yellow
    Get-ComputerRestorePoint | Delete-ComputerRestorePoints # -WhatIf 
}
if ($result -eq 1) { 
    Write-Host "You answered NO, continuing script." 
}

Write-Host "Capture current free disk space on Drive C" -foreground yellow
$FreespaceBefore = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | select Freespace).FreeSpace / 1GB

Write-host "Deleting Rouge folders" -foreground yellow
if (test-path C:\Config.Msi) {remove-item -Path C:\Config.Msi -force -recurse}
if (test-path c:\Intel) {remove-item -Path c:\Intel -force -recurse}
if (test-path c:\PerfLogs) {remove-item -Path c:\PerfLogs -force -recurse}
if (test-path c:\swsetup) {remove-item -Path c:\swsetup -force -recurse} # HP Software and Driver Repositry
if (test-path $env:windir\memory.dmp) {remove-item $env:windir\memory.dmp -force}

Write-host "Deleting Windows Error Reporting files" -foreground yellow
if (test-path C:\ProgramData\Microsoft\Windows\WER) {Get-ChildItem -Path C:\ProgramData\Microsoft\Windows\WER -Recurse | Remove-Item -force -recurse}

Write-host "Removing System and User Temp Files" -foreground yellow
Remove-Item -Path "$env:windir\Temp\*" -Force -Recurse
Remove-Item -Path "$env:windir\minidump\*" -Force -Recurse
Remove-Item -Path "$env:windir\Prefetch\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Temp\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\WER\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\IECompatCache\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\IECompatUaCache\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\IEDownloadHistory\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\INetCache\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\INetCookies\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Terminal Server Client\Cache\*" -Force -Recurse

Write-host "Removing Windows Updates Downloads" -foreground yellow
Stop-Service wuauserv -Force -Verbose
Stop-Service TrustedInstaller -Force -Verbose
Remove-Item -Path "$env:windir\SoftwareDistribution\*" -Force -Recurse
Remove-Item $env:windir\Logs\CBS\* -force -recurse
Start-Service wuauserv -Verbose
Start-Service TrustedInstaller -Verbose

Write-host "Clearing All Event Logs. PLease wait..." -foreground yellow
wevtutil el >$null 2>&1 | Foreach-Object {Write-Host "Clearing $_"; wevtutil cl "$_" >$null 2>&1} >$null 2>&1 
Write-host "Disk Usage before and after cleanup: (Counts in GB)" -foreground yellow
$FreespaceAfter = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | select Freespace).FreeSpace / 1GB
"Free Space Before (GB): {0}" -f $FreespaceBefore
"Free Space After (GB): {0}" -f $FreespaceAfter 
Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');