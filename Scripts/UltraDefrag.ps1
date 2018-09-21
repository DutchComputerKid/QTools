function pause {
    Write-Host 'Press any key to continue...';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}
function UDDownload {
    Write-host "Downloading UltraDefrag for your architecture.." -ForegroundColor yellow
    
    If ((Get-CimInstance Win32_operatingsystem).OSArchitecture -contains "64-bit") {
        Write-Host "Detected an x64 system."
        $url = "https://downloads.sourceforge.net/ultradefrag/ultradefrag-7.0.2.bin.amd64.exe"
    }
    else {
        Write-Host "Detected an x86 system."
        $url = ""
    }

    $output = ".\Data\UltraDefrag.exe"
    $start_time = Get-Date

    Import-Module BitsTransfer
    Start-BitsTransfer -Source $url -Destination $output
    #OR -Asynchronous

    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
    Write-Host "Looking for and removing TMP files..."
    get-childitem ".\" -recurse -force -include *.TMP| remove-item -force
}

function CommandLineInstall {
    Write-Host ""
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Application]::EnableVisualStyles()

    #region begin GUI{ 

    $Form = New-Object system.Windows.Forms.Form
    $Form.ClientSize = '263,143'
    $Form.text = "Choose Features"
    $Form.TopMost = $false

    $Description = New-Object system.Windows.Forms.TextBox
    $Description.multiline = $true
    $Description.width = 200
    $Description.height = 50
    $Description.location = New-Object System.Drawing.Point(24, 20)
    $Description.Font = 'Microsoft Sans Serif,10'

    $CheckBox1 = New-Object system.Windows.Forms.CheckBox
    $CheckBox1.text = "Shortcuts"
    $CheckBox1.AutoSize = $false
    $CheckBox1.width = 95
    $CheckBox1.height = 20
    $CheckBox1.location = New-Object System.Drawing.Point(24, 86)
    $CheckBox1.Font = 'Microsoft Sans Serif,10'

    $CheckBox2 = New-Object system.Windows.Forms.CheckBox
    $CheckBox2.text = "Shell Extension"
    $CheckBox2.AutoSize = $true
    $CheckBox2.width = 95
    $CheckBox2.height = 20
    $CheckBox2.location = New-Object System.Drawing.Point(137, 85)
    $CheckBox2.Font = 'Microsoft Sans Serif,10'

    $CheckBox3 = New-Object system.Windows.Forms.CheckBox
    $CheckBox3.text = "Silent Install"
    $CheckBox3.AutoSize = $true
    $CheckBox3.width = 95
    $CheckBox3.height = 20
    $CheckBox3.location = New-Object System.Drawing.Point(24, 114)
    $CheckBox3.Font = 'Microsoft Sans Serif,10'

    $Launcher = New-Object system.Windows.Forms.Button
    $Launcher.text = "Execute"
    $Launcher.width = 65
    $Launcher.height = 30
    $Launcher.location = New-Object System.Drawing.Point(154, 106)
    $Launcher.Font = 'Microsoft Sans Serif,10'

    $Form.controls.AddRange(@($Description, $CheckBox1, $CheckBox2, $CheckBox3, $Launcher))
        
    #Analyzing input...
    $global:Arguments = "/FULL "
    $CheckBox1.add_click( {
            $Description.Text = "Include all shortcuts."
            if (!($global:Arguments -contains "/ICONS=1 ")) {
                $global:Arguments = $global:Arguments + "/ICONS=1 "
            }
            $form.Update()
        })

    $CheckBox2.add_click( {
            $Description.Text = "This will put a right click function on Explorer for direct defragmentation"
            if (!($global:Arguments -contains "/SHELLEXTENSION=1 ")) {
                $global:Arguments = $global:Arguments + "/SHELLEXTENSION=1 "
            }
            $form.Update()
        })

    $CheckBox3.add_click( {
            $Description.Text = "This won't show the process and install in the background."
            if (!($global:Arguments -contains "/S ")) {
                $global:Arguments = $global:Arguments + "/S "
            }
            $form.Update()
        })

    $Launcher.add_click( {
            $Form.Close()
            $form.Update()
        })
    [void]$Form.ShowDialog()

    $global:Arguments = ($global:Arguments -split ' ' | Select-Object -Unique) -join ' '
    if ($checkbox1.checked -eq $false) {
        if ("$global:Arguments".Contains("/ICONS=1")) {
            $global:Arguments = $global:Arguments.Replace("/ICONS=1 ", "")
        }
    }
    if ($checkbox2.checked -eq $false) {
        if ("$global:Arguments".Contains("/SHELLEXTENSION=")) {
            $global:Arguments = $global:Arguments.Replace("/SHELLEXTENSION=1 ", "")
        }
    }
    if ($checkbox3.checked -eq $false) {
        if ("$global:Arguments".Contains("/S")) {
            $global:Arguments = $global:Arguments.Replace("/S ", "")
        }
    }

    Write-Host "Chosen command line options are: " $global:Arguments
    Write-Host "Now performing the command line automated installation. Please wait.." -ForegroundColor Yellow
    Start-Process -FilePath ".\Data\UltraDefrag.exe" -ArgumentList "$global:Arguments" -WindowStyle Normal -Wait
    Write-Host "Complete!" -ForegroundColor Green
}


$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", ""
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", ""
$choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$caption = "Welcome!"
Write-Host "UltraDefrag is a disk defragmenter for Windows, which instead of selecting only the most fragmented files and consolidating them, it uses the whole disk." -ForegroundColor Yellow
$message = "Would you like to use this software?"
$result = $Host.UI.PromptForChoice($caption, $message, $choices, 0)
if ($result -eq 0) { 
    try {
        Write-Host ""
        Write-Host "You answered YES, please wait."
        UDDownload

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
    Write-Host "You answered NO exciting script." 
    exit
}

Write-Host "You can either use the regular or automated installation."
Write-Host "With regular, you make the choices and use the graphical installer."
Write-Host "With automatic, we do the work for you and make it install silently."

$choice = ""
while ($choice -notmatch "[a|r]") {
    $choice = read-host "Automated or regular installation?"
    if ($choice = "automated") {$choice = "a"}
    if ($choice = "regular") {$choice = "r"}

}

if ($choice -eq "r") {
    Write-Host "Launching installer..." -ForegroundColor Red
    Start-Process -FilePath ".\Data\UltraDefrag.exe"  -WindowStyle Normal -Wait

}
if ($choice -eq "a") {
    CommandLineInstall
}
   
Write-Host "Script completed!"
pause