$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", ""
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", ""
$choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$caption = "Warning!"
Write-Host "This script has a lot of tools, but we cannot guarantee that everything will work correctly." -foreground yellow
Write-Host "I have tested it again and again and everything works. But in a real-world scenario, I cannot say that you won't encounter problems." -foreground yellow
Write-Host "If you're not sure about all this, then make a System Restore Point. Would you like me to do that for you?" -foreground yellow
$message = "Do you want to create a restore point?"
$result = $Host.UI.PromptForChoice($caption, $message, $choices, 0)
if ($result -eq 0) { 
    try {
        Clear-Host
        Write-Host "You answered YES, please wait."
        write-host "Attempting System Restore Point creation..."
        Checkpoint-Computer -Description 'QCleaner safety point' -RestorePointType modify_settings
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
    Write-Host "You answered NO, continuing script." 
    exit
}

