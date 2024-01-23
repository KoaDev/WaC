Import-Module Functional
Import-Module Pester-ShouldBeDeep

BeforeAll {
    . $PSScriptRoot\Yaml.ps1
    . $PSScriptRoot\Compare-DscConfigurationState.ps1
}

Describe 'MyDscConfiguration' {
    Context 'Compare-DscConfigurationState' {
        It 'should call Compare-DscResourceState with the expected parameters when given a single resource' {
            $expected = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'Key4'
                    ValueName = 'Value4'
                }
            }

            Mock Compare-DscResourceState { @{ Status = 'Error' } } -Verifiable

            Compare-DscConfigurationState -Resources @($expected)

            Assert-MockCalled Compare-DscResourceState -Times 1 -Scope It -ParameterFilter {
                $Resource.Name -eq $expected.Name -and
                $Resource.Property.Key -eq $expected.Property.Key -and
                $Resource.Property.ValueName -eq $expected.Property.ValueName
            }
        }

        It 'should call Compare-DscResourceState with the expected parameters when given multiple resources' {
            $expected = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'Key5'
                    ValueName = 'Value5'
                }
            }

            Mock Compare-DscResourceState { @{ Status = 'Error' } } -Verifiable

            Compare-DscConfigurationState -Resources @($expected, $expected)

            Assert-MockCalled Compare-DscResourceState -Times 2 -Scope It -ParameterFilter {
                $Resource.Name -eq $expected.Name -and
                $Resource.Property.Key -eq $expected.Property.Key -and
                $Resource.Property.ValueName -eq $expected.Property.ValueName
            }
        }

        It 'should call Compare-DscResourceState with the expected parameters when given a YAML file path' {
            $expected = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'Key6'
                    ValueName = 'Value6'
                }
            }
            
            # Setup Phase: Create a temporary file
            $tempFile = [System.IO.Path]::GetTempFileName()
            Export-DscResourcesToYaml -YamlFilePath $tempFile -DscResources @($expected)

            Mock Compare-DscResourceState { @{ Status = 'Error' } } -Verifiable
    
            Compare-DscConfigurationState -YamlFilePath $tempFile
    
            Assert-MockCalled Compare-DscResourceState -Times 1 -Scope It -ParameterFilter {
                $Resource.Name -eq $expected.Name -and
                $Resource.Property.Key -eq $expected.Property.Key -and
                $Resource.Property.ValueName -eq $expected.Property.ValueName
            }
            
            # Teardown Phase: Delete the temporary file
            if (Test-Path $tempFile)
            {
                Remove-Item $tempFile -Force
            }
        }

        It 'should return non compliant only by default' {
            $expected = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'Key7'
                    ValueName = 'Value7'
                }
            }

            Mock Compare-DscResourceState { @{ Status = 'Compliant' } } -Verifiable

            $result = Compare-DscConfigurationState -Resources @($expected)

            $result.Compliant | Should -BeNullOrEmpty
            $result.NonCompliant | Should -BeNullOrEmpty
            $result.Missing | Should -BeNullOrEmpty
            $result.Unexpected | Should -BeNullOrEmpty
            $result.Error | Should -BeNullOrEmpty
        }

        It 'should return compliant when given the -WithCompliant switch' {
            $expected = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'Key8'
                    ValueName = 'Value8'
                }
            }

            Mock Compare-DscResourceState { @{ Status = 'Compliant' } } -Verifiable

            $result = Compare-DscConfigurationState -Resources @($expected) -WithCompliant

            $result.Compliant | Should -Not -BeNullOrEmpty
            $result.NonCompliant | Should -BeNullOrEmpty
            $result.Missing | Should -BeNullOrEmpty
            $result.Unexpected | Should -BeNullOrEmpty
            $result.Error | Should -BeNullOrEmpty
        }
    }
}
