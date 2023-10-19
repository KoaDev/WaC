# Import the PSDesiredStateConfiguration module
Import-Module PSDesiredStateConfiguration

# Define the properties for the HideFileExt registry entry
$hideFileExtProperties = @{
    Key       = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    ValueName = 'HideFileExt'
    ValueType = 'DWord'
    Ensure    = 'Present'
}

# Retrieve the current value for HideFileExt
$hideFileExtCurrentValue = Invoke-DscResource -Name Registry -ModuleName PSDesiredStateConfiguration -Method Get -Property $hideFileExtProperties

# Check the difference for HideFileExt
if ($hideFileExtCurrentValue.ValueData -ne '0') {
    "HideFileExt current value: $($hideFileExtCurrentValue.ValueData) - Desired value: 0"
}
else {
    "HideFileExt is in desired state."
}

# Define the properties for the DisableLoopbackCheck registry entry
$disableLoopbackCheckProperties = @{
    Key       = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa'
    ValueName = 'DisableLoopbackCheck'
    ValueType = 'DWord'
    Ensure    = 'Present'
}

# Retrieve the current value for DisableLoopbackCheck
$disableLoopbackCheckCurrentValue = Invoke-DscResource -Name Registry -ModuleName PSDesiredStateConfiguration -Method Get -Property $disableLoopbackCheckProperties

# Check the difference for DisableLoopbackCheck
if ($disableLoopbackCheckCurrentValue.ValueData -ne '1') {
    "DisableLoopbackCheck current value: $($disableLoopbackCheckCurrentValue.ValueData) - Desired value: 1"
}
else {
    "DisableLoopbackCheck is in desired state."
}
