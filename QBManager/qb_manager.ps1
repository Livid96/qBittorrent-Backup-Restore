# --------------------------- Hide Console ---------------------------
Add-Type -Name Win -Namespace Console -MemberDefinition '
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd,int nCmdShow);
'
$consolePtr = [Console.Win]::GetConsoleWindow()
[Console.Win]::ShowWindow($consolePtr,0)  # 0=Hide

# --------------------------- Admin Elevation ---------------------------
function Ensure-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        $psi.Verb = "runas"
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        exit
    }
}
Ensure-Admin

# --------------------------- Load Assemblies ---------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --------------------------- Config Initialization ---------------------------
$configFile = "$PSScriptRoot\config.txt"
$defaultFolder = "$env:USERPROFILE\Desktop"

if (-not (Test-Path $configFile)) {
    $defaultFolder | Set-Content $configFile
}

$global:backupDir = Get-Content $configFile

# --------------------------- BackupOnly Silent Mode ---------------------------
if ($BackupOnly) {

    $global:backupDir = $Folder
    if (!(Test-Path $global:backupDir)) { New-Item $global:backupDir -ItemType Directory | Out-Null }

    $today = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $todayFile = "$global:backupDir\qbittorrent_auto_$today.zip"
    if (Test-Path $todayFile) { exit }

    if ($Mode -eq "Weekly" -and (Get-Date).DayOfWeek -ne "Sunday") { exit }

    $local = "$env:LOCALAPPDATA\qBittorrent"
    $roaming = "$env:APPDATA\qBittorrent"
    $temp = "$env:TEMP\qb_backup"

    Remove-Item $temp -Recurse -Force -ErrorAction Ignore
    New-Item -ItemType Directory -Path $temp | Out-Null
    New-Item "$temp\Local" -ItemType Directory -Force | Out-Null
    New-Item "$temp\Roaming" -ItemType Directory -Force | Out-Null

    Copy-Item "$local\*" "$temp\Local" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item "$roaming\*" "$temp\Roaming" -Recurse -Force -ErrorAction SilentlyContinue

    Compress-Archive "$temp\*" $todayFile -Force
    Remove-Item $temp -Recurse -Force

    Get-ChildItem $global:backupDir -Filter "qbittorrent_auto_*.zip" |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
        Remove-Item -Force -ErrorAction SilentlyContinue

    exit
}

# --------------------------- Create Form ---------------------------
$form = New-Object Windows.Forms.Form
$form.Text = "qBittorrent Manager"
$form.WindowState = 'Normal'
$form.FormBorderStyle = 'Sizable'
$form.MinimumSize = New-Object Drawing.Size(520,600)
$form.StartPosition = 'CenterScreen'
$form.BackColor = "#1e1e1e"
$font = New-Object Drawing.Font("Segoe UI",10)

# --------------------------- Folder Label ---------------------------
$folderLabel = New-Object Windows.Forms.Label
$folderLabel.Size = New-Object Drawing.Size(480,25)
$folderLabel.Location = New-Object Drawing.Point(20,10)
$folderLabel.ForeColor = "white"
$folderLabel.Text = "Backup Folder: $global:backupDir"
$folderLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($folderLabel)


# --------------------------- Progress Bar ---------------------------
$progress = New-Object Windows.Forms.ProgressBar
$progress.Size = New-Object Drawing.Size(480,20)
$progress.Location = New-Object Drawing.Point(20,540)
$progress.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($progress)

# --------------------------- Progress Fill ---------------------------
$progressFill = New-Object Windows.Forms.Panel
$progressFill.Size = New-Object Drawing.Size(0,20)
$progressFill.Location = New-Object Drawing.Point(0,0)

# HEX Color here
$progressFill.BackColor = [Drawing.ColorTranslator]::FromHtml("#ff0000")

$progressBG.Controls.Add($progressFill)



# --------------------------- Popup Message Function ---------------------------
function Show-PopupMessage {
    param([string]$Message,[int]$DurationMs=2000)
    $popupForm = New-Object System.Windows.Forms.Form
    $popupForm.Size = New-Object System.Drawing.Size(450,80)
    $popupForm.FormBorderStyle = "None"
    $popupForm.StartPosition = "CenterScreen"
    $popupForm.TopMost = $true
    $popupForm.BackColor = "#007700"

    $label = New-Object System.Windows.Forms.Label
    $label.AutoSize = $true
    $label.Font = New-Object System.Drawing.Font("Segoe UI",20,[System.Drawing.FontStyle]::Bold)
    $label.ForeColor = "White"
    $label.Text = $Message.ToUpper()
    $label.Location = New-Object System.Drawing.Point(20,20)
    $popupForm.Controls.Add($label)

    $popupForm.Show()
    Start-Sleep -Milliseconds $DurationMs
    $popupForm.Close()
}

# --------------------------- Folder Selection ---------------------------
$folderBtn = New-Object Windows.Forms.Button
$folderBtn.Text = "Select Backup Folder"
$folderBtn.Size = New-Object Drawing.Size(480,35)
$folderBtn.Location = New-Object Drawing.Point(20,40)
$folderBtn.BackColor = "#a57900"
$folderBtn.ForeColor = "white"
$folderBtn.Font = $font
$folderBtn.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($folderBtn)

$folderBtn.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ([string]::IsNullOrEmpty($global:backupDir)) { $dialog.SelectedPath = "$env:USERPROFILE\Desktop" }
    else { $dialog.SelectedPath = $global:backupDir }

    if ($dialog.ShowDialog() -eq "OK") {
        $global:backupDir = $dialog.SelectedPath
        $folderLabel.Text = "Backup Folder: $global:backupDir"
        $global:backupDir | Set-Content $configFile
        Show-PopupMessage "FOLDER SELECTED"
        Load-RestoreList
    }
})

# --------------------------- Backup Button ---------------------------
$backupBtn = New-Object Windows.Forms.Button
$backupBtn.Text = "Backup Now"
$backupBtn.Size = New-Object Drawing.Size(480,40)
$backupBtn.Location = New-Object Drawing.Point(20,100)
$backupBtn.BackColor = "#006fb9"
$backupBtn.ForeColor = "white"
$backupBtn.Font = $font
$backupBtn.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($backupBtn)

$backupBtn.Add_Click({
    if (!(Test-Path $global:backupDir)) { New-Item $global:backupDir -ItemType Directory | Out-Null }

    $progress.Value = 10
    $local = "$env:LOCALAPPDATA\qBittorrent"
    $roaming = "$env:APPDATA\qBittorrent"
    if (!(Test-Path $global:backupDir)) { New-Item -ItemType Directory -Path $global:backupDir | Out-Null }

    $date = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $temp = "$env:TEMP\qb_backup"

    Remove-Item $temp -Recurse -Force -ErrorAction Ignore
    New-Item -ItemType Directory -Path $temp | Out-Null
    New-Item "$temp\Local" -ItemType Directory -Force | Out-Null
    New-Item "$temp\Roaming" -ItemType Directory -Force | Out-Null

    Copy-Item "$local\*" "$temp\Local" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item "$roaming\*" "$temp\Roaming" -Recurse -Force -ErrorAction SilentlyContinue

    $zipFile = "$global:backupDir\qbittorrent_backup_$date.zip"
    Compress-Archive -Path "$temp\*" -DestinationPath $zipFile -Force
    Remove-Item $temp -Recurse -Force

    $progress.Value = 100
    Show-PopupMessage "BACKUP SUCCESSFUL"
    $progress.Value = 0
    Load-RestoreList
})

# --------------------------- Restore List and Buttons ---------------------------
$restoreLabel = New-Object Windows.Forms.Label
$restoreLabel.Text = "Select Backup to Restore:"
$restoreLabel.ForeColor = "white"
$restoreLabel.Location = New-Object Drawing.Point(20,160)
$restoreLabel.Size = New-Object Drawing.Size(480,20)
$restoreLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($restoreLabel)

$restoreList = New-Object Windows.Forms.ListBox
$restoreList.Size = New-Object Drawing.Size(480,150)
$restoreList.Location = New-Object Drawing.Point(20,180)
$restoreList.BackColor = "#2e2e2e"
$restoreList.ForeColor = "white"
$restoreList.Font = New-Object System.Drawing.Font("Segoe UI",10)
$restoreList.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($restoreList)

function Load-RestoreList {
    $restoreList.Items.Clear()
    if (Test-Path $global:backupDir) {
        $zips = Get-ChildItem $global:backupDir -Filter "*.zip" | Sort-Object LastWriteTime -Descending
        foreach ($zip in $zips) { $restoreList.Items.Add($zip.Name) }
    }
}

Load-RestoreList

# --------------------------- Restore Button ---------------------------
$restoreBtn = New-Object Windows.Forms.Button
$restoreBtn.Text = "Restore Backup"
$restoreBtn.Size = New-Object Drawing.Size(480,40)
$restoreBtn.Location = New-Object Drawing.Point(20,340)
$restoreBtn.BackColor = "#008a39"
$restoreBtn.ForeColor = "white"
$restoreBtn.Font = $font
$restoreBtn.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($restoreBtn)

$restoreBtn.Add_Click({
    if ($restoreList.SelectedItem -eq $null) {
        Show-PopupMessage "PLEASE SELECT A BACKUP"
        return
    }

    $progress.Value = 10
    $zipFile = Join-Path $global:backupDir $restoreList.SelectedItem
    $temp = "$env:TEMP\qb_restore"

    Remove-Item $temp -Recurse -Force -ErrorAction Ignore
    New-Item -ItemType Directory -Path $temp | Out-Null

    $progress.Value = 30
    Expand-Archive -Path $zipFile -DestinationPath $temp -Force

    $progress.Value = 50
    $localTarget = "$env:LOCALAPPDATA\qBittorrent"
    $roamingTarget = "$env:APPDATA\qBittorrent"

    Remove-Item $localTarget -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $roamingTarget -Recurse -Force -ErrorAction SilentlyContinue
    New-Item $localTarget -ItemType Directory -Force | Out-Null
    New-Item $roamingTarget -ItemType Directory -Force | Out-Null

    Copy-Item "$temp\Local\*" $localTarget -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item "$temp\Roaming\*" $roamingTarget -Recurse -Force -ErrorAction SilentlyContinue

    Remove-Item $temp -Recurse -Force
    $progress.Value = 100
    Show-PopupMessage "RESTORE SUCCESSFUL"
    $progress.Value = 0
})

# --------------------------- Wipe Data ---------------------------
$wipeBtn = New-Object Windows.Forms.Button
$wipeBtn.Text = "Wipe Data"
$wipeBtn.Size = New-Object Drawing.Size(480,40)
$wipeBtn.Location = New-Object Drawing.Point(20,400)
$wipeBtn.BackColor = "#b22222"
$wipeBtn.ForeColor = "white"
$wipeBtn.Font = $font
$wipeBtn.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($wipeBtn)

$wipeBtn.Add_Click({
    Get-Process qbittorrent -ErrorAction SilentlyContinue | Stop-Process -Force
    Remove-Item "$env:LOCALAPPDATA\qBittorrent" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:APPDATA\qBittorrent" -Recurse -Force -ErrorAction SilentlyContinue
    Show-PopupMessage "WIPE DATA SUCCESSFUL"
    Load-RestoreList
})

# --------------------------- Auto Backup Enable/Disable ---------------------------
$enableAuto = New-Object Windows.Forms.Button
$enableAuto.Text = "Enable Auto Backup"
$enableAuto.Size = New-Object Drawing.Size(480,40)
$enableAuto.Location = New-Object Drawing.Point(20,460)
$enableAuto.BackColor = "#333333"
$enableAuto.ForeColor = "white"
$enableAuto.Font = $font
$enableAuto.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($enableAuto)

$disableAuto = New-Object Windows.Forms.Button
$disableAuto.Text = "Disable Auto Backup"
$disableAuto.Size = New-Object Drawing.Size(480,40)
$disableAuto.Location = New-Object Drawing.Point(20,510)
$disableAuto.BackColor = "#333333"
$disableAuto.ForeColor = "white"
$disableAuto.Font = $font
$disableAuto.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($disableAuto)

# Auto Backup Enable
$enableAuto.Add_Click({
    $autoForm = New-Object Windows.Forms.Form
    $autoForm.Size = New-Object Drawing.Size(300,150)
    $autoForm.StartPosition = "CenterParent"
    $autoForm.Text = "Choose Auto Backup Type"

    $daily = New-Object Windows.Forms.RadioButton
    $daily.Text = "Daily Backup"
    $daily.Location = New-Object Drawing.Point(20,20)
    $daily.Checked = $true
    $autoForm.Controls.Add($daily)

    $weekly = New-Object Windows.Forms.RadioButton
    $weekly.Text = "Weekly Backup"
    $weekly.Location = New-Object Drawing.Point(20,50)
    $autoForm.Controls.Add($weekly)

    $okBtn = New-Object Windows.Forms.Button
    $okBtn.Text = "OK"
    $okBtn.Location = New-Object Drawing.Point(100,90)
    $okBtn.Add_Click({ $autoForm.Tag = if ($daily.Checked) {1} else {2}; $autoForm.Close() })
    $autoForm.Controls.Add($okBtn)

    $autoForm.ShowDialog() | Out-Null
    $choice = $autoForm.Tag

    if ($choice -eq 1) {
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $taskName = "QBT Daily Backup"
        Show-PopupMessage "QBT DAILY BACKUP ENABLED"
    } elseif ($choice -eq 2) {
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 9pm
        $taskName = "QBT Weekly Backup"
        Show-PopupMessage "QBT WEEKLY BACKUP ENABLED"
    } else { return }

    # Use latest global:backupDir for scheduled task
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\qb_manager.ps1`" -BackupOnly -Folder `"$global:backupDir`""
    Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Force
})

# Auto Backup Disable
$disableAuto.Add_Click({
    Unregister-ScheduledTask -TaskName "QBT Daily Backup" -Confirm:$false -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName "QBT Weekly Backup" -Confirm:$false -ErrorAction SilentlyContinue
    Show-PopupMessage "AUTO BACKUP DISABLED"
})

# --------------------------- Show Form ---------------------------
$form.ShowDialog()