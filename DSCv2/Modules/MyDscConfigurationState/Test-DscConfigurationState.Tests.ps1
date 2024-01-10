Import-Module Functional
Import-Module Pester-ShouldBeDeep

BeforeAll {
    . $PSScriptRoot\Test-DscConfigurationState.ps1
}

Describe 'MyDscConfiguration' {
    Context 'Test-DscConfigurationState' {
        It 'should call Invoke-DscResourceState with the expected parameters' {
            $expected = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'Key6'
                    ValueName = 'Value6'
                }
            }
    
            Mock Invoke-DscResourceState { $args } -Verifiable
    
            Test-DscConfigurationState -Resources @($expected)
    
            Assert-MockCalled Invoke-DscResourceState -Times 1 -Scope It -ParameterFilter {
                $Method -eq 'Test'
            }
        }
    }
}
