Configuration MyDotnetWorkstation {
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node 'localhost' {
        Registry DisableLoopbackCheckSetting {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName = "DisableLoopbackCheck"
            ValueData = "1"
            ValueType = "Dword"
        }
        
        Registry HideFileExtSetting {
            Ensure    = "Present"
            Key       = "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            ValueName = "HideFileExt"
            ValueData = "0"
            ValueType = "Dword"
        }
    }
}

# Create the configuration (generates MOF file)
MyDotnetWorkstation

# Apply the configuration
# Start-DscConfiguration -Path .\MyDotnetWorkstation -Wait -Verbose
