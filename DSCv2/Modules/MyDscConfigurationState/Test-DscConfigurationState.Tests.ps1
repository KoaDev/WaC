Import-Module Functional
Import-Module Pester-ShouldBeDeep

BeforeAll {
    . $PSScriptRoot\Test-DscConfigurationState.ps1
}

Describe 'MyDscConfiguration' {
    Context 'Test-DscConfigurationState' {
        It 'should call Invoke-DscResourceState with the expected parameters when given a resource collection' {
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

        It 'should call Invoke-DscResourceState with the expected parameters when given a yaml file path' {
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
            
            Mock Invoke-DscResourceState { $args } -Verifiable
    
            Test-DscConfigurationState -YamlFilePath $tempFile
    
            Assert-MockCalled Invoke-DscResourceState -Times 1 -Scope It -ParameterFilter {
                $Method -eq 'Test'
            }        

            # Teardown Phase: Delete the temporary file
            if (Test-Path $tempFile)
            {
                Remove-Item $tempFile -Force
            }
        }
    }
}
