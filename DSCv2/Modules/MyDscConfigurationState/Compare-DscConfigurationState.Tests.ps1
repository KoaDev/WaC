Import-Module Functional
Import-Module Pester-ShouldBeDeep

BeforeAll {
    . $PSScriptRoot\Yaml.ps1
    . $PSScriptRoot\Compare-DscConfigurationState.ps1
}

Describe 'MyDscConfiguration' {
    Context 'Compare-DscConfigurationState' {
        # It 'should call Invoke-DscResourceStateBatch with the expected parameters when given a resource collection' {
        #     $expected = @{
        #         Name     = 'Registry'
        #         Property = @{
        #             Key       = 'Key6'
        #             ValueName = 'Value6'
        #         }
        #     }
    
        #     Mock Invoke-DscResourceStateBatch { $args } -Verifiable
    
        #     Get-DscConfigurationState -Resources @($expected)
    
        #     Assert-MockCalled Invoke-DscResourceStateBatch -Times 1 -Scope It -ParameterFilter {
        #         $Method -eq 'Get' -and
        #         $Resources[0] -eq $expected
        #     }
        # }

        It 'should call Invoke-DscResourceStateBatch with the expected parameters when given a YAML file path' {
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

            Mock Invoke-DscResourceStateBatch { $args } -Verifiable
    
            Get-DscConfigurationState -YamlFilePath $tempFile
    
            Assert-MockCalled Invoke-DscResourceStateBatch -Times 1 -Scope It -ParameterFilter {
                $Method -eq 'Get' -and
                $Resources[0].Name -eq $expected.Name -and
                $Resources[0].Property.Key -eq $expected.Property.Key -and
                $Resources[0].Property.ValueName -eq $expected.Property.ValueName
            }
            
            # Teardown Phase: Delete the temporary file
            if (Test-Path $tempFile)
            {
                Remove-Item $tempFile -Force
            }
        }
    }
}
