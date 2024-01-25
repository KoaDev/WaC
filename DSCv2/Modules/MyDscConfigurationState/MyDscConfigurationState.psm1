Get-ChildItem -Path "$PSScriptRoot\*.ps1" -Exclude '*.Tests.ps1' | ForEach-Object { . $_.FullName }

Export-ModuleMember `
    -Function Get-DscConfigurationState, Test-DscConfigurationState, Set-DscConfigurationState, Compare-DscConfigurationState
