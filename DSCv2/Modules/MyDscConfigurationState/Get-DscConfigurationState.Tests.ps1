Import-Module Functional
Import-Module Pester-ShouldBeDeep

BeforeAll {
    . $PSScriptRoot\Get-DscConfigurationState.ps1
}

Describe 'MyDscConfiguration' {
    Context 'Get-DscConfigurationState' {
        It 'should call Invoke-DscResourceState with the expected parameters when given a resource collection' {
            $expected = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'Key6'
                    ValueName = 'Value6'
                }
            }
    
            Mock Invoke-DscResourceState { $args } -Verifiable
    
            Get-DscConfigurationState -Resources @($expected)
    
            Assert-MockCalled Invoke-DscResourceState -Times 1 -Scope It -ParameterFilter {
                $Method -eq 'Get' -and
                $Resources[0] -eq $expected -and
                $YamlFilePath -eq $null
            }
        }

        It 'should call Invoke-DscResourceState with the expected parameters when given a YAML file path' {
            Mock Invoke-DscResourceState { $args } -Verifiable
    
            Get-DscConfigurationState -YamlFilePath "$PSScriptRoot\MyDscConfigurationState.yaml"
    
            Assert-MockCalled Invoke-DscResourceState -Times 1 -Scope It -ParameterFilter {
                $Method -eq 'GET' -and
                $Resources -eq $null -and
                $YamlFilePath -eq "$PSScriptRoot\MyDscConfigurationState.yaml"
            }
        }
    }
}
