Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# List of apps: Display name and internal Appx package name
$debloatItems = @(
    @{ Name = "Xbox Apps"; App = "Microsoft.XboxApp" },
    @{ Name = "People"; App = "Microsoft.People" },
    @{ Name = "Skype"; App = "Microsoft.SkypeApp" },
    @{ Name = "Cortana (Win10)"; App = "Microsoft.Windows.Cortana" },
    @{ Name = "Office Hub"; App = "Microsoft.MicrosoftOfficeHub" },
    @{ Name = "OneDrive"; App = "OneDrive" },
    @{ Name = "Groove Music"; App = "Microsoft.ZuneMusic" },
    @{ Name = "Movies & TV"; App = "Microsoft.ZuneVideo" },
    @{ Name = "Paint 3D"; App = "Microsoft.MSPaint" },
    @{ Name = "Get Help"; App = "Microsoft.GetHelp" },
    @{ Name = "Feedback Hub"; App = "Microsoft.WindowsFeedbackHub" },
    @{ Name = "Tips"; App = "Microsoft.Getstarted" }
)

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Debloater GUI"
$form.Size = New-Object System.Drawing.Size(420, 560)
$form.StartPosition = "CenterScreen"

# Instruction label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Select the apps/services to remove:"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($label)

# Dynamic checkboxes
$checkboxes = @()
$y = 40
foreach ($item in $debloatItems) {
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $item.Name
    $cb.Tag = $item.App
    $cb.AutoSize = $true
    $cb.Location = New-Object System.Drawing.Point(20, $y)
    $form.Controls.Add($cb)
    $checkboxes += $cb
    $y += 25
}

# Progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, $y + 10)
$progressBar.Size = New-Object System.Drawing.Size(360, 20)
$progressBar.Minimum = 0
$progressBar.Maximum = $checkboxes.Count
$form.Controls.Add($progressBar)

# Output box
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.ReadOnly = $true
$outputBox.Size = New-Object System.Drawing.Size(360, 150)
$outputBox.Location = New-Object System.Drawing.Point(20, $y + 40)
$form.Controls.Add($outputBox)

# Debloat button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Debloat Selected"
$button.Size = New-Object System.Drawing.Size(150, 30)
$button.Location = New-Object System.Drawing.Point(130, $y + 200)
$form.Controls.Add($button)

# Action on click
$button.Add_Click({
    $outputBox.Clear()
    $progressBar.Value = 0

    $selected = $checkboxes | Where-Object { $_.Checked }
    $total = $selected.Count
    if ($total -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Select at least one item to debloat.","Nothing Selected")
        return
    }

    foreach ($cb in $selected) {
        $appName = $cb.Tag
        $displayName = $cb.Text

        if ($appName -eq "OneDrive") {
            $uninstaller = "$env:SystemRoot\System32\OneDriveSetup.exe"
            if (Test-Path $uninstaller) {
                Start-Process $uninstaller "/uninstall" -NoNewWindow -Wait
                $outputBox.AppendText("✔ Removed: OneDrive`r`n")
            } else {
                $outputBox.AppendText("⚠ OneDrive uninstaller not found.`r`n")
            }
        } else {
            $pkg = Get-AppxPackage -Name $appName -ErrorAction SilentlyContinue
            if ($pkg) {
                try {
                    Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
                    $outputBox.AppendText("Removed: $displayName`r`n")
                } catch {
                    $outputBox.AppendText("Failed to remove: $displayName`r`n")
                }
            } else {
                $outputBox.AppendText("ℹ Not installed: $displayName`r`n")
            }

            # Registry cleanup
            $regPaths = @(
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Appx\PackageRepository"
            )
            foreach ($reg in $regPaths) {
                Get-ChildItem -Path $reg -Recurse -ErrorAction SilentlyContinue | Where-Object {
                    $_.Name -like "*$appName*"
                } | ForEach-Object {
                    try {
                        Remove-Item -Path $_.PsPath -Recurse -Force -ErrorAction Stop
                        $outputBox.AppendText("🧹 Registry cleaned: $($_.PsPath)`r`n")
                    } catch {
                        $outputBox.AppendText("⚠ Failed to clean registry: $($_.PsPath)`r`n")
                    }
                }
            }
        }

        # Update progress
        $progressBar.Value += 1
        Start-Sleep -Milliseconds 300
    }

    $outputBox.AppendText("Debloat complete!`r`n")
})

# Show GUI
$form.Topmost = $true
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
