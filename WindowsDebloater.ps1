#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# List of apps: Display name and internal Appx package names.
# "Patterns" supports multiple package names per entry (wildcards allowed).
$debloatItems = @(
    @{ Name = "Xbox Apps";        Patterns = @("Microsoft.XboxApp", "Microsoft.XboxGamingOverlay", "Microsoft.XboxGameOverlay", "Microsoft.XboxSpeechToTextOverlay", "Microsoft.Xbox.TCUI") },
    @{ Name = "People";           Patterns = @("Microsoft.People") },
    @{ Name = "Skype";            Patterns = @("Microsoft.SkypeApp") },
    @{ Name = "Cortana";          Patterns = @("Microsoft.Windows.Cortana", "Microsoft.549981C3F5F10") },
    @{ Name = "Office Hub";       Patterns = @("Microsoft.MicrosoftOfficeHub") },
    @{ Name = "OneDrive";         Special  = "OneDrive" },
    @{ Name = "Groove Music";     Patterns = @("Microsoft.ZuneMusic") },
    @{ Name = "Movies & TV";      Patterns = @("Microsoft.ZuneVideo") },
    @{ Name = "Paint 3D";         Patterns = @("Microsoft.MSPaint") },
    @{ Name = "Get Help";         Patterns = @("Microsoft.GetHelp") },
    @{ Name = "Feedback Hub";     Patterns = @("Microsoft.WindowsFeedbackHub") },
    @{ Name = "Tips";             Patterns = @("Microsoft.Getstarted") },
    @{ Name = "Bing News";        Patterns = @("Microsoft.BingNews") },
    @{ Name = "Bing Weather";     Patterns = @("Microsoft.BingWeather") },
    @{ Name = "Maps";             Patterns = @("Microsoft.WindowsMaps") },
    @{ Name = "Solitaire";        Patterns = @("Microsoft.MicrosoftSolitaireCollection") },
    @{ Name = "Clipchamp";        Patterns = @("Clipchamp.Clipchamp") },
    @{ Name = "Teams (consumer)"; Patterns = @("MicrosoftTeams", "MSTeams") }
)

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Debloater GUI" + $(if ($isAdmin) { " (Administrator)" } else { "" })
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.StartPosition = "CenterScreen"

# Instruction label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Select the apps/services to remove:"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($label)

# Checkboxes in two columns
$checkboxes = @()
$rows = [math]::Ceiling($debloatItems.Count / 2)
for ($i = 0; $i -lt $debloatItems.Count; $i++) {
    $col = [math]::Floor($i / $rows)
    $row = $i % $rows
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $debloatItems[$i].Name
    $cb.Tag = $debloatItems[$i]
    $cb.AutoSize = $true
    $cb.Location = New-Object System.Drawing.Point((20 + $col * 200), (35 + $row * 24))
    $form.Controls.Add($cb)
    $checkboxes += $cb
}
$y = 35 + $rows * 24 + 10

# Option: also remove provisioned packages so apps stay gone for new users (admin only)
$provisionedCb = New-Object System.Windows.Forms.CheckBox
$provisionedCb.Text = "Also remove for new user accounts (provisioned packages)"
$provisionedCb.AutoSize = $true
$provisionedCb.Enabled = $isAdmin
$provisionedCb.Location = New-Object System.Drawing.Point(20, $y)
$form.Controls.Add($provisionedCb)
if (-not $isAdmin) {
    $tooltip = New-Object System.Windows.Forms.ToolTip
    $tooltip.SetToolTip($provisionedCb, "Run the script as Administrator to enable this option.")
}
$y += 30

# Select all / clear buttons
$selectAllBtn = New-Object System.Windows.Forms.Button
$selectAllBtn.Text = "Select All"
$selectAllBtn.Size = New-Object System.Drawing.Size(85, 26)
$selectAllBtn.Location = New-Object System.Drawing.Point(20, $y)
$selectAllBtn.Add_Click({ foreach ($cb in $checkboxes) { $cb.Checked = $true } })
$form.Controls.Add($selectAllBtn)

$clearBtn = New-Object System.Windows.Forms.Button
$clearBtn.Text = "Clear"
$clearBtn.Size = New-Object System.Drawing.Size(85, 26)
$clearBtn.Location = New-Object System.Drawing.Point(115, $y)
$clearBtn.Add_Click({ foreach ($cb in $checkboxes) { $cb.Checked = $false } })
$form.Controls.Add($clearBtn)
$y += 36

# Progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, $y)
$progressBar.Size = New-Object System.Drawing.Size(384, 20)
$form.Controls.Add($progressBar)
$y += 30

# Output box
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.ReadOnly = $true
$outputBox.Size = New-Object System.Drawing.Size(384, 160)
$outputBox.Location = New-Object System.Drawing.Point(20, $y)
$form.Controls.Add($outputBox)
$y += 170

# Debloat button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Debloat Selected"
$button.Size = New-Object System.Drawing.Size(150, 30)
$button.Location = New-Object System.Drawing.Point(137, $y)
$form.Controls.Add($button)
$y += 45

# Size the client area to fit the controls (avoids title-bar height guesswork)
$form.ClientSize = New-Object System.Drawing.Size(424, $y)

function Write-Log([string]$Message) {
    $outputBox.AppendText("[{0}] {1}`r`n" -f (Get-Date -Format "HH:mm:ss"), $Message)
    [System.Windows.Forms.Application]::DoEvents()
}

function Remove-OneDrive {
    # Stop the running client first, otherwise the uninstall can silently fail
    Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue

    # Per-user installs register an uninstall string; machine installs ship OneDriveSetup.exe
    $uninstaller = $null
    $argList = "/uninstall"
    $reg = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe" -ErrorAction SilentlyContinue
    if ($reg -and $reg.UninstallString -match '^"?(.+?OneDriveSetup\.exe)"?\s*(.*)$') {
        $uninstaller = $Matches[1]
        if ($Matches[2]) { $argList = $Matches[2] }
    }
    if (-not $uninstaller) {
        $uninstaller = @(
            "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
            "$env:SystemRoot\System32\OneDriveSetup.exe"
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    }

    if ($uninstaller) {
        Start-Process $uninstaller $argList -NoNewWindow -Wait
        Write-Log "Removed: OneDrive"
    } else {
        Write-Log "OneDrive uninstaller not found."
    }
}

function Remove-AppxItem($Item, [bool]$Provisioned, $ProvisionedPackages) {
    foreach ($pattern in $Item.Patterns) {
        $getParams = @{ Name = $pattern; ErrorAction = "SilentlyContinue" }
        if ($isAdmin) { $getParams.AllUsers = $true }
        $pkgs = @(Get-AppxPackage @getParams)

        if ($pkgs.Count -eq 0) {
            Write-Log "Not installed: $($Item.Name) ($pattern)"
        }
        foreach ($pkg in $pkgs) {
            try {
                if ($isAdmin) {
                    Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                } else {
                    Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
                }
                Write-Log "Removed: $($pkg.Name)"
            } catch {
                Write-Log "Failed to remove $($pkg.Name): $($_.Exception.Message)"
            }
        }

        # Remove the provisioned copy so the app is not installed for new user accounts
        if ($Provisioned -and $ProvisionedPackages) {
            foreach ($prov in ($ProvisionedPackages | Where-Object { $_.DisplayName -like $pattern })) {
                try {
                    Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop | Out-Null
                    Write-Log "Removed provisioned: $($prov.DisplayName)"
                } catch {
                    Write-Log "Failed to remove provisioned $($prov.DisplayName): $($_.Exception.Message)"
                }
            }
        }
    }
}

# Action on click
$button.Add_Click({
    $selected = @($checkboxes | Where-Object { $_.Checked })
    if ($selected.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Select at least one item to debloat.", "Nothing Selected")
        return
    }

    $button.Enabled = $false
    $outputBox.Clear()
    $progressBar.Value = 0
    $progressBar.Maximum = $selected.Count

    # Fetch the provisioned package list once (DISM call is slow)
    $provisionedPackages = $null
    if ($provisionedCb.Checked) {
        Write-Log "Reading provisioned packages..."
        $provisionedPackages = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }

    foreach ($cb in $selected) {
        $item = $cb.Tag
        if ($item.Special -eq "OneDrive") {
            Remove-OneDrive
        } else {
            Remove-AppxItem $item $provisionedCb.Checked $provisionedPackages
        }
        $progressBar.Value += 1
    }

    Write-Log "Debloat complete!"
    $button.Enabled = $true
})

# Show GUI
$form.Topmost = $true
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
