Get-ChildItem -Path "$PSScriptRoot\*.ps1" -Exclude '*.Tests.ps1' | ForEach-Object { . $_.FullName }

Export-ModuleMember `
    -Function Get-DscResourceState, Test-DscResourceState, Set-DscResourceState, Compare-DscResourceState, Select-DscResourceIdProperties, Select-DscResourceStateProperties `
    -Variable DscResourcesIdProperties
