# Windows Debloater GUI (PowerShell)

A simple PowerShell WinForms GUI to remove selected preinstalled Windows apps (Appx packages) and uninstall OneDrive. It provides a checklist UI, progress bar, and a log output box.

This script removes apps for the currently logged-in user (it uses Remove-AppxPackage, not provisioning removal for new users).
Some Windows components may not be removable or may be reinstalled by Windows updates.
The registry cleanup is aggressive (recursive delete of matching keys under HKCU paths). Use with caution and consider removing that part if you want a safer “apps only” debloat.

## Disclaimer

Use at your own risk. Removing built-in apps and deleting registry keys can affect system functionality. Test in a VM or on a non-critical system first.

## What this script does

### 1) Shows a GUI with selectable items
The script opens a Windows Forms window titled **“Windows Debloater GUI”** and lists debloat targets as checkboxes.

Included targets:
- Xbox Apps (`Microsoft.XboxApp`)
- People (`Microsoft.People`)
- Skype (`Microsoft.SkypeApp`)
- Cortana (Win10) (`Microsoft.Windows.Cortana`)
- Office Hub (`Microsoft.MicrosoftOfficeHub`)
- OneDrive (handled separately)
- Groove Music (`Microsoft.ZuneMusic`)
- Movies & TV (`Microsoft.ZuneVideo`)
- Paint 3D (`Microsoft.MSPaint`)
- Get Help (`Microsoft.GetHelp`)
- Feedback Hub (`Microsoft.WindowsFeedbackHub`)
- Tips (`Microsoft.Getstarted`)

### 2) Removes selected Appx apps (current user)
For each selected item (except OneDrive):
- Checks if the Appx package is installed for the current user using `Get-AppxPackage -Name <package>`
- If found, removes it using `Remove-AppxPackage -Package <PackageFullName>`
- If not found, logs “Not installed”

### 3) Uninstalls OneDrive (special case)
If **OneDrive** is selected:
- Tries to run:
  - `%SystemRoot%\System32\OneDriveSetup.exe /uninstall`
- Logs success or warns if the uninstaller is not found

### 4) Attempts registry cleanup (HKCU)
After removing an Appx app, it attempts to remove registry entries that match the app name under:
- `HKCU:\Software\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore`
- `HKCU:\Software\Microsoft\Windows\CurrentVersion\Appx\PackageRepository`

It recursively searches for keys containing the package name string and tries to delete them. Results are logged.

### 5) Provides progress + logging
- Progress bar increments per selected item processed
- Output text box logs actions taken and errors
- Shows a message box if nothing is selected

## Requirements

- Windows PowerShell (or PowerShell) on Windows
- Ability to run WinForms (normal Windows desktop session)
- Permissions:
  - Removing Appx packages usually works per-user without full admin, but some packages may fail depending on system policy
  - Registry cleanup targets HKCU (current user) only

## How to run

1. Save the script as `debloater-gui.ps1`
2. Open PowerShell
3. (Optional) allow script execution for the current session:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass


   To add or remove items, edit the $debloatItems list:
   $debloatItems = @(
  @{ Name = "Example"; App = "Publisher.AppName" }
)

You can find package names with:
Get-AppxPackage | Select Name, PackageFullName

