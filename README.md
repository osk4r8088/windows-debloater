# Windows Debloater GUI (PowerShell)

A simple PowerShell WinForms GUI to remove selected preinstalled Windows apps and uninstall OneDrive.

- Without admin rights, apps are removed for the currently logged-in user only.
- When run as Administrator, apps are removed for **all users**, and you can optionally remove the **provisioned packages** so the apps are not installed for new user accounts (and are less likely to come back after Windows updates).
- Some Windows components may not be removable or may be reinstalled by Windows updates (depending on the update / Windows version you currently have).

## Disclaimer

Use at your own risk. Removing built-in apps can affect system functionality.

Test in a VM or on a non-critical system first if unsure.

## What this script does

### 1) Shows a GUI with selectable items
The script opens a Windows Forms window titled **"Windows Debloater GUI"** and lists debloat targets as checkboxes (two columns), with **Select All** / **Clear** buttons.

Included targets:
- Xbox Apps (`Microsoft.XboxApp`, `Microsoft.XboxGamingOverlay`, `Microsoft.XboxGameOverlay`, `Microsoft.XboxSpeechToTextOverlay`, `Microsoft.Xbox.TCUI`)
- People (`Microsoft.People`)
- Skype (`Microsoft.SkypeApp`)
- Cortana (`Microsoft.Windows.Cortana` on Win10, `Microsoft.549981C3F5F10` on Win11)
- Office Hub (`Microsoft.MicrosoftOfficeHub`)
- OneDrive (handled separately)
- Groove Music (`Microsoft.ZuneMusic`)
- Movies & TV (`Microsoft.ZuneVideo`)
- Paint 3D (`Microsoft.MSPaint`)
- Get Help (`Microsoft.GetHelp`)
- Feedback Hub (`Microsoft.WindowsFeedbackHub`)
- Tips (`Microsoft.Getstarted`)
- Bing News (`Microsoft.BingNews`)
- Bing Weather (`Microsoft.BingWeather`)
- Maps (`Microsoft.WindowsMaps`)
- Solitaire (`Microsoft.MicrosoftSolitaireCollection`)
- Clipchamp (`Clipchamp.Clipchamp`)
- Teams consumer app (`MicrosoftTeams`, `MSTeams`)

### 2) Removes selected Appx apps
For each selected item (except OneDrive):
- Checks if the Appx package is installed using `Get-AppxPackage` (with `-AllUsers` when running as admin)
- If found, removes it using `Remove-AppxPackage` (with `-AllUsers` when running as admin)
- If not found, logs "Not installed"
- If the *"Also remove for new user accounts"* option is checked (admin only), the matching provisioned package is removed via `Remove-AppxProvisionedPackage`

### 3) Uninstalls OneDrive
If **OneDrive** is selected:
- Stops the running `OneDrive.exe` process first
- Looks up the per-user uninstall string in `HKCU:\...\Uninstall\OneDriveSetup.exe`
- Falls back to `%SystemRoot%\SysWOW64\OneDriveSetup.exe` or `%SystemRoot%\System32\OneDriveSetup.exe`
- Logs success or warns if no uninstaller is found

### 4) Provides progress + logging
- Progress bar increments per selected item processed
- Output text box logs actions with timestamps, including error details
- Shows a message box if nothing is selected

> Note: earlier versions of this script also performed a recursive registry cleanup under the HKCU Appx store paths. That was removed — `Remove-AppxPackage` already cleans up its own registration, and force-deleting matching keys risks corrupting the Appx package state.

## Requirements

- Windows PowerShell 5.1+
- Ability to run WinForms
- Permissions:
  - Removing Appx packages usually works per-user without full admin, but some packages may fail depending on system policy
  - `-AllUsers` removal and provisioned-package removal require running the script as Administrator

## How to run

1. Save the script as `WindowsDebloater.ps1`
2. Open PowerShell (as Administrator for the all-users / provisioned options)
3. (Optional) Allow script execution for the current session:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

## Customization (add/remove apps)
Edit the `$debloatItems` list in the script. Each entry can match multiple package names (wildcards allowed):

```powershell
$debloatItems = @(
    @{ Name = "Example"; Patterns = @("Publisher.AppName", "Publisher.OtherApp*") }
)
```

To find installed package names:
```powershell
Get-AppxPackage | Select Name, PackageFullName
```
