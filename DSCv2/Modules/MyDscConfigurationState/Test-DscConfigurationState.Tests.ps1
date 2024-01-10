Import-Module Functional
Import-Module Pester-ShouldBeDeep

BeforeAll {
    . $PSScriptRoot\Test-DscConfigurationState.ps1
}

Describe 'MyDscConfiguration' {
    Context 'Test-DscConfigurationStateFromResources' {
        It 'should call Test-DscResourceState with the expected parameters' {
            $expected = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'Key1'
                    ValueName = 'Value1'
                }
            }

            Mock Test-DscResourceState { $args } -Verifiable

            Test-DscConfigurationStateFromResources -Resources @($expected)

            Assert-MockCalled Test-DscResourceState -Times 1 -Scope It -ParameterFilter {
                $resource.Name -eq $expected.Name -and
                $resource.Property.Key -eq $expected.Property.Key -and
                $resource.Property.ValueName -eq $expected.Property.ValueName
            }
        }

        It 'should call Test-DscResourceState for each resource' {
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

            Mock Test-DscResourceState { $args } -Verifiable

            Test-DscConfigurationStateFromResources -Resources $expected

            Assert-MockCalled Test-DscResourceState -Times 1 -Scope It -ParameterFilter {
                $resource.Name -eq $expected[0].Name -and
                $resource.Property.Key -eq $expected[0].Property.Key -and
                $resource.Property.ValueName -eq $expected[0].Property.ValueName
            }

            Assert-MockCalled Test-DscResourceState -Times 1 -Scope It -ParameterFilter {
                $resource.Name -eq $expected[1].Name -and
                $resource.Property.Key -eq $expected[1].Property.Key -and
                $resource.Property.ValueName -eq $expected[1].Property.ValueName
            }
        }
        
        It 'should use cache when possible' {
            $expected = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'Key4'
                    ValueName = 'Value4'
                }
            }

            Mock Test-DscResourceState { $args } -Verifiable

            Test-DscConfigurationStateFromResources -Resources @($expected)
            Test-DscConfigurationStateFromResources -Resources @($expected)

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

            Test-DscConfigurationStateFromResources -Resources @($expected)
            Test-DscConfigurationStateFromResources -Resources @($expected) -Force

            Assert-MockCalled Test-DscResourceState -Times 2 -Scope It -ParameterFilter {
                $resource.Name -eq $expected.Name -and
                $resource.Property.Key -eq $expected.Property.Key -and
                $resource.Property.ValueName -eq $expected.Property.ValueName
            }
        }
    }

    Context 'Test-DscConfigurationState' {
        It 'should call Test-DscConfigurationStateFromResources with the expected parameters when given a resource collection' {
            $expected = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'Key6'
                    ValueName = 'Value6'
                }
            }

            Mock Test-DscConfigurationStateFromResources { $args } -Verifiable

            Test-DscConfigurationState -Resources @($expected)

            Assert-MockCalled Test-DscConfigurationStateFromResources -Times 1 -Scope It -ParameterFilter {
                $resources.Name -eq $expected.Name -and
                $resources.Property.Key -eq $expected.Property.Key -and
                $resources.Property.ValueName -eq $expected.Property.ValueName
            }
        }

        It 'should call Test-DscConfigurationStateFromResources with the expected parameters when given a YAML file path' {
            Mock Test-DscConfigurationStateFromResources { $args } -Verifiable

            Test-DscConfigurationState -YamlFilePath "$PSScriptRoot\MyDscConfigurationState.yaml"

            Assert-MockCalled Test-DscConfigurationStateFromResources -Times 1 -Scope It -ParameterFilter {
                $resources.Name -eq 'Registry' -and
                $resources.Property.Key -eq 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -and
                $resources.Property.ValueName -eq 'HideFileExt'
            }
        }
    }
}
