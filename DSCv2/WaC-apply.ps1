# Import the PSDesiredStateConfiguration module
Import-Module PSDesiredStateConfiguration

# Define the properties for setting HideFileExt registry entry
$hideFileExtProperties = @{
    Key       = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    ValueName = 'HideFileExt'
    ValueData = '0'
    ValueType = 'DWord'
    Ensure    = 'Present'
}

# Apply the HideFileExt registry configuration
$hideFileExtResult = Invoke-DscResource -Name Registry -ModuleName PSDesiredStateConfiguration -Method Set -Property $hideFileExtProperties

# Define the properties for setting DisableLoopbackCheck registry entry
$disableLoopbackCheckProperties = @{
    Key       = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa'
    ValueName = 'DisableLoopbackCheck'
    ValueData = '1'
    ValueType = 'DWord'
    Ensure    = 'Present'
}

# Apply the DisableLoopbackCheck registry configuration
$disableLoopbackCheckResult = Invoke-DscResource -Name Registry -ModuleName PSDesiredStateConfiguration -Method Set -Property $disableLoopbackCheckProperties

# Output the results
$hideFileExtResult
$disableLoopbackCheckResult
