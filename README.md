https://stackoverflow.com/questions/68992255/why-cant-export-variable-members-in-a-powershell-module-using-variablestoexport

https://powershellexplained.com/2016-11-06-powershell-hashtable-everything-you-wanted-to-know-about/#using-the-brackets-for-access
https://powershellexplained.com/2016-10-28-powershell-everything-you-wanted-to-know-about-pscustomobject/

https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-7.4

https://www.red-gate.com/simple-talk/sysadmin/powershell/powershell-time-saver-automatic-defaults/

// Check for PS modules updates

```powershell
Get-InstalledModule | ForEach-Object {
    $installedModule = $_
    # Determine if the installed module is a prerelease
    $isPrerelease = $installedModule.Version -match '-'
    $findModuleParams = @{
        Name = $installedModule.Name
    }
    if ($isPrerelease) {
        $findModuleParams['AllowPrerelease'] = $true
    }

    $latestModule = Find-Module @findModuleParams

    # Use version comparison that accounts for prerelease
    $installedVersion = $installedModule.Version
    $latestVersion = $latestModule.Version

    # Only proceed if there's a version difference, considering prerelease status
    if ($isPrerelease -or ($installedVersion -ne $latestVersion)) {
        # Further check to ensure we're only reporting genuine updates
        if (-not $isPrerelease -or ($isPrerelease -and $installedVersion -ne $latestVersion)) {
            [PSCustomObject]@{
                ModuleName = $installedModule.Name
                InstalledVersion = $installedModule.Version
                LatestVersion = $latestModule.Version
            }
        }
    }
} | Where-Object { $_ } | Format-Table -AutoSize
```

// Update PS module

```powershell
Update-Module -Name ModuleName
```
