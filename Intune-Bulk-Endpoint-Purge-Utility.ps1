# ==============================================================================
# Script: Intune-Bulk-Endpoint-Purge-Utility.ps1
# Version: 1.0
# Developer: Open Source Contributor
# Purpose: GUI-based enterprise tool for secure bulk removal of Intune devices.
# Documentation:
#   - Requires input CSV with a header in cell A1 named 'DeviceName'
#   - Automatically outputs detailed time-stamped CSV logs to a \Reports folder
# ==============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- [Environment & Infrastructure] ---
$ScriptPath = $PSScriptRoot
if ([string]::IsNullOrEmpty($ScriptPath)) { $ScriptPath = Get-Location }

# Auto-manage the Reports subfolder for clean log archiving
$ReportFolder = Join-Path -Path $ScriptPath -ChildPath "Reports"
if (-not (Test-Path $ReportFolder)) { New-Item -ItemType Directory -Path $ReportFolder -Force | Out-Null }

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.WebRequest]::DefaultWebProxy = [System.Net.WebRequest]::GetSystemWebProxy()
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

# --- [Helper Functions] ---
function Update-ListBox {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    if ($listBoxLog) {
        $listBoxLog.Items.Add("[$timestamp] $Message") | Out-Null
        $listBoxLog.TopIndex = $listBoxLog.Items.Count - 1
        [System.Windows.Forms.Application]::DoEvents()
    }
}

# --- [GUI Construction] ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Intune Bulk Endpoint Purge Utility"
$form.Size = New-Object System.Drawing.Size(600, 680)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Branding Header
$headerLabel = New-Object System.Windows.Forms.Label
$headerLabel.Text = "INTUNE BULK ENDPOINT PURGE UTILITY"
$headerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$headerLabel.ForeColor = [System.Drawing.Color]::DarkSlateGray
$headerLabel.Location = New-Object System.Drawing.Point(20, 15)
$headerLabel.AutoSize = $true
$form.Controls.Add($headerLabel)

# Account Status Tracking
$userLabel = New-Object System.Windows.Forms.Label
$userLabel.Text = "Account: Not Connected"
$userLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$userLabel.Location = New-Object System.Drawing.Point(20, 50)
$userLabel.AutoSize = $true
$form.Controls.Add($userLabel)

# Operational Instructions Group
$groupInstructions = New-Object System.Windows.Forms.GroupBox
$groupInstructions.Text = "Requirements"
$groupInstructions.Location = New-Object System.Drawing.Point(20, 75)
$groupInstructions.Size = New-Object System.Drawing.Size(540, 50)
$form.Controls.Add($groupInstructions)

$instrLabel = New-Object System.Windows.Forms.Label
$instrLabel.Text = "CSV Header A1: 'DeviceName'. Ensure you have active PIM elevation before running."
$instrLabel.Location = New-Object System.Drawing.Point(10, 20)
$instrLabel.AutoSize = $true
$groupInstructions.Controls.Add($instrLabel)

# Inputs: Entra Tenant ID
$lblTenantId = New-Object System.Windows.Forms.Label
$lblTenantId.Text = "Entra Tenant ID:"
$lblTenantId.Location = New-Object System.Drawing.Point(20, 135)
$lblTenantId.AutoSize = $true
$form.Controls.Add($lblTenantId)

$txtTenantId = New-Object System.Windows.Forms.TextBox
$txtTenantId.Location = New-Object System.Drawing.Point(20, 155)
$txtTenantId.Size = New-Object System.Drawing.Size(540, 20)
$form.Controls.Add($txtTenantId)

# Inputs: App Registration Client ID
$lblClientId = New-Object System.Windows.Forms.Label
$lblClientId.Text = "App Registration Client ID:"
$lblClientId.Location = New-Object System.Drawing.Point(20, 185)
$lblClientId.AutoSize = $true
$form.Controls.Add($lblClientId)

$txtClientId = New-Object System.Windows.Forms.TextBox
$txtClientId.Location = New-Object System.Drawing.Point(20, 205)
$txtClientId.Size = New-Object System.Drawing.Size(540, 20)
$form.Controls.Add($txtClientId)

# File Import Path Bar
$lblFile = New-Object System.Windows.Forms.Label
$lblFile.Text = "Target CSV File:"
$lblFile.Location = New-Object System.Drawing.Point(20, 235)
$lblFile.AutoSize = $true
$form.Controls.Add($lblFile)

$txtFilePath = New-Object System.Windows.Forms.TextBox
$txtFilePath.Location = New-Object System.Drawing.Point(20, 255)
$txtFilePath.Size = New-Object System.Drawing.Size(430, 20)
$txtFilePath.ReadOnly = $true
$form.Controls.Add($txtFilePath)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Location = New-Object System.Drawing.Point(460, 253)
$btnBrowse.Text = "Browse..."
$form.Controls.Add($btnBrowse)

# Execution Visual Feedback
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 285)
$progressBar.Size = New-Object System.Drawing.Size(540, 20)
$form.Controls.Add($progressBar)

$listBoxLog = New-Object System.Windows.Forms.ListBox
$listBoxLog.Location = New-Object System.Drawing.Point(20, 315)
$listBoxLog.Size = New-Object System.Drawing.Size(540, 180)
$form.Controls.Add($listBoxLog)

# Execution Control Trigger
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Location = New-Object System.Drawing.Point(20, 515)
$btnStart.Size = New-Object System.Drawing.Size(540, 50)
$btnStart.Text = "EXECUTE BULK REMOVAL"
$btnStart.BackColor = [System.Drawing.Color]::LightGreen
$btnStart.Enabled = $false
$btnStart.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($btnStart)

# --- [Logic & Events] ---

$btnBrowse.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog
    $fd.Filter = "CSV Files (*.csv)|*.csv"
    if ($fd.ShowDialog() -eq "OK") {
        try {
            $txtFilePath.Text = $fd.FileName
            $global:CsvData = @(Import-Csv -Path $fd.FileName -ErrorAction Stop)

            if ($global:CsvData.Count -gt 0 -and $global:CsvData[0].PSObject.Properties.Name -contains "DeviceName") {
                $btnStart.Enabled = $true
                Update-ListBox "Loaded $($global:CsvData.Count) devices from manifest."
            } else {
                [System.Windows.Forms.MessageBox]::Show("CSV Structure Error: Column header must be exactly 'DeviceName'.", "Validation Failure", 0, 16)
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Could not open CSV target. Confirm the file is not locked by Excel.", "File Access Exception", 0, 16)
        }
    }
})

$btnStart.Add_Click({
    $TID = $txtTenantId.Text.Trim()
    $CID = $txtClientId.Text.Trim()

    if ([string]::IsNullOrEmpty($TID) -or [string]::IsNullOrEmpty($CID)) {
        [System.Windows.Forms.MessageBox]::Show("Validation Error: Please provide both the Entra Tenant ID and App Registration Client ID.", "Configuration Blocked", 0, 48)
        return
    }

    $Confirm = [System.Windows.Forms.MessageBox]::Show("CRITICAL ACTION: This execution will permanently purge $($global:CsvData.Count) devices from the target environment.`n`nDo you want to authorize this operation?", "Authorization Required", 4, 48)
    if ($Confirm -eq "No") { return }

    $btnStart.Enabled = $false; $btnBrowse.Enabled = $false
    $ResultsLog = @(); $SuccessCount = 0; $FailCount = 0; $NotFoundCount = 0

    Update-ListBox "Initializing engine deployment..."
    Disconnect-MgGraph | Out-Null

    try {
        Connect-MgGraph -ClientId $CID -TenantId $TID -Scopes "DeviceManagementManagedDevices.ReadWrite.All" -ContextScope Process -NoWelcome

        $ctx = Get-MgContext
        if (-not $ctx) { throw "Graph infrastructure identity confirmation failed." }

        $userLabel.Text = "Identity Profile: $($ctx.Account)"
        $userLabel.ForeColor = [System.Drawing.Color]::DarkGreen
        Update-ListBox "Secure tunnel to endpoint directory established."
    } catch {
        Update-ListBox "CONNECTIVITY FAULT: $($_.Exception.Message)"
        $btnStart.Enabled = $true; $btnBrowse.Enabled = $true; return
    }

    $progressBar.Maximum = $global:CsvData.Count
    foreach ($i in 0..($global:CsvData.Count-1)) {
        $Hostname = $global:CsvData[$i].DeviceName
        $progressBar.Value = $i + 1
        [System.Windows.Forms.Application]::DoEvents()

        try {
            $IntuneDev = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$Hostname'" -ErrorAction Stop
            if ($IntuneDev) {
                Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $IntuneDev.Id -ErrorAction Stop
                Update-ListBox "[PASS] Purged $Hostname"
                $ResultsLog += [PSCustomObject]@{ DeviceName = $Hostname; Status = "Success"; Details = "Deleted via Automation Pipeline"; Timestamp = (Get-Date) }
                $SuccessCount++
            } else {
                Update-ListBox "[SKIP] $Hostname absent"
                $ResultsLog += [PSCustomObject]@{ DeviceName = $Hostname; Status = "Skipped"; Details = "Object record absent from directory."; Timestamp = (Get-Date) }
                $NotFoundCount++
            }
        } catch {
            # Advanced Error Scrubber Engine
            $RawError = $_.Exception.Message
            $CleanError = "Directory Write Contradiction"

            if ($RawError -match "Forbidden") { $CleanError = "Privilege Level Insufficient" }
            elseif ($RawError -match "NotFound") { $CleanError = "Target entity not tracked" }

            Update-ListBox "[FAIL] $Hostname Processing Aborted"
            $ResultsLog += [PSCustomObject]@{ DeviceName = $Hostname; Status = "Error Exception"; Details = $CleanError; Timestamp = (Get-Date) }
            $FailCount++
        }
    }

    # Mandatory Automated Governance Exporting
    $FinalPath = Join-Path -Path $ReportFolder -ChildPath "Purge_Audit_Report_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
    $ResultsLog | Export-Csv -Path $FinalPath -NoTypeInformation

    Disconnect-MgGraph

    # Final Operational Metric Matrix Dashboard
    $SummaryMsg = "Data Processing Phase Finalized.`n`n" +
                  "Target Manifest Volume: $($global:CsvData.Count)`n" +
                  "Completely Purged: $SuccessCount`n" +
                  "Directory Missing: $NotFoundCount`n" +
                  "Processing Exceptions: $FailCount`n`n" +
                  "Central Immutable Audit Trail Created at:`n$FinalPath"

    [System.Windows.Forms.MessageBox]::Show($SummaryMsg, "Endpoint Compliance Audit Dashboard", 0, 64)

    $btnStart.Enabled = $true; $btnBrowse.Enabled = $true
})

$form.ShowDialog() | Out-Null
