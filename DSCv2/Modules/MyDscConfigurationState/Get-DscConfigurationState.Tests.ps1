Import-Module Functional
Import-Module Pester-ShouldBeDeep

BeforeAll {
    . $PSScriptRoot\Get-DscConfigurationState.ps1
}

Describe 'MyDscConfiguration' {
    Context 'Get-DscConfigurationState' {
        It 'should return the expected result' {
            $result = Get-DscConfigurationState -YamlFilePath "$PSScriptRoot\MyDscConfigurationState.yaml"
            $result | Should -BeDeep @(
                @{
                    Type       = 'Registry'
                    Identifier = @{
                        Key       = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                        ValueName = 'HideFileExt'
                    }
                    State      = @{
                        ValueType = 'DWord'
                        ValueData = @(0)
                        Ensure    = 'Present'
                    }
                }
            )
        }
    }
}
