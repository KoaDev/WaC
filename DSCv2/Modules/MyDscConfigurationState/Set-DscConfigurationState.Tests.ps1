Import-Module Functional
Import-Module Pester-ShouldBeDeep

BeforeAll {
    . $PSScriptRoot\Test-DscConfigurationState.ps1
    . $PSScriptRoot\Set-DscConfigurationState.ps1
}

Describe 'MyDscConfiguration' {
    Context 'Test-DscConfigurationState' {
        It 'should not call Set-DscResourceState when the resources has been tested and is in the desired state' {
            $expected = @{
                Name       = 'WinGetPackage'
                ModuleName = 'Microsoft.WinGet.DSC'
                Property   = @{
                    Id = 'Microsoft.PowerShell'
                }
            }

            Mock Set-DscResourceState { $args } -Verifiable
    
            Test-DscConfigurationState -Resources @($expected)
            Set-DscConfigurationState -Resources @($expected)

            Assert-MockCalled Set-DscResourceState -Times 0 -Exactly
        }

        It 'should call Set-DscResourceState when the resources has not been tested' {
            $expected = @{
                Name       = 'WinGetPackage'
                ModuleName = 'Microsoft.WinGet.DSC'
                Property   = @{
                    Id = 'Microsoft.PowerShell'
                }
            }

            Mock Set-DscResourceState { $args } -Verifiable
    
            Set-DscConfigurationState -Resources @($expected)

            Assert-MockCalled Set-DscResourceState -Times 1 -Exactly
        }

        It 'should call Set-DscResourceState when the resources has been tested but the force switch is used' {
            $expected = @{
                Name       = 'WinGetPackage'
                ModuleName = 'Microsoft.WinGet.DSC'
                Property   = @{
                    Id = 'Microsoft.PowerShell'
                }
            }

            Mock Set-DscResourceState { $args } -Verifiable
    
            Test-DscConfigurationState -Resources @($expected)
            Set-DscConfigurationState -Resources @($expected) -Force

            Assert-MockCalled Set-DscResourceState -Times 1 -Exactly
        }
    }
}
