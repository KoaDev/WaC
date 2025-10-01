Import-Module Functional
Import-Module Pester-ShouldBeDeep

BeforeAll {
    . $PSScriptRoot\Invoke-DscResourceState.ps1
}

Describe 'MyDscConfiguration' {
    Context 'Invoke-DscResourceStateBatch' {
        It 'should call Invoke-DscResourceState with the expected parameters when given a single resource' {
            $expected = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'Key1'
                    ValueName = 'Value1'
                }
            }

            Mock Invoke-DscResourceState { $args } -Verifiable

            Invoke-DscResourceStateBatch -Method Test -Resources @($expected)

            Assert-MockCalled Invoke-DscResourceState -Times 1 -Scope It -ParameterFilter {
                $Method -eq 'Test' -and
                $Resource.Name -eq $expected.Name -and
                $Resource.Property.Key -eq $expected.Property.Key -and
                $Resource.Property.ValueName -eq $expected.Property.ValueName
                $Force -eq $false
            }
        }

        It 'should call Invoke-DscResourceState with the expected parameters when given multiple resources' {
            $expected = @(
                @{
                    Name     = 'Registry'
                    Property = @{
                        Key       = 'Key2'
                        ValueName = 'Value2'
                    }
                },
                @{
                    Name     = 'Registry'
                    Property = @{
                        Key       = 'Key3'
                        ValueName = 'Value3'
                    }
                }
            )

            Mock Invoke-DscResourceState { $args } -Verifiable

            Invoke-DscResourceStateBatch -Method Test -Resources $expected

            Assert-MockCalled Invoke-DscResourceState -Times 1 -Scope It -ParameterFilter {
                $Method -eq 'Test' -and
                $Resource.Name -eq $expected[0].Name -and
                $Resource.Property.Key -eq $expected[0].Property.Key -and
                $Resource.Property.ValueName -eq $expected[0].Property.ValueName
                $Force -eq $false
            }

            Assert-MockCalled Invoke-DscResourceState -Times 1 -Scope It -ParameterFilter {
                $Method -eq 'Test' -and
                $Resource.Name -eq $expected[1].Name -and
                $Resource.Property.Key -eq $expected[1].Property.Key -and
                $Resource.Property.ValueName -eq $expected[1].Property.ValueName
                $Force -eq $false
            }
        }
    }

    Context 'Invoke-DscResourceState' {
        It 'should use cache when possible' {
            $expected = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'Key4'
                    ValueName = 'Value4'
                }
            }

            Mock Test-DscResourceState { $args } -Verifiable

            Invoke-DscResourceState -Method Test -Resource $expected
            Invoke-DscResourceState -Method Test -Resource $expected

            Assert-MockCalled Test-DscResourceState -Times 1 -Scope It -ParameterFilter {
                $resource.Name -eq $expected.Name -and
                $resource.Property.Key -eq $expected.Property.Key -and
                $resource.Property.ValueName -eq $expected.Property.ValueName
            }
        }

        It 'should call Test-DscResourceState with the expected parameters when the cache is outdated' {
            $expected = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'Key5'
                    ValueName = 'Value5'
                }
            }

            Mock Test-DscResourceState { $args } -Verifiable

            Invoke-DscResourceState -Method Test -Resource $expected
            Invoke-DscResourceState -Method Test -Resource $expected -Force

            Assert-MockCalled Test-DscResourceState -Times 2 -Scope It -ParameterFilter {
                $resource.Name -eq $expected.Name -and
                $resource.Property.Key -eq $expected.Property.Key -and
                $resource.Property.ValueName -eq $expected.Property.ValueName
            }
        }
    }
}
