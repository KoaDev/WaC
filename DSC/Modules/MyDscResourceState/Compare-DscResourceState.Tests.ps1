Import-Module Functional
Import-Module Pester-ShouldBeDeep

BeforeAll {
    . $PSScriptRoot\Compare-DscResourceState.ps1
}

Describe 'MyDscResourceState' {
    Context 'Compare-DscResourceState' {
        It 'Gets the status and diff when the actual and expected state of a resource are the same' {
            # Arrange: Set up any preconditions and inputs
            $resource = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                    ValueName = 'HideFileExt'
                    ValueType = 'DWord'
                    ValueData = @('0')
                    Ensure    = 'Present'
                }
            }

            # Act: Run the function to test
            $result = Compare-DscResourceState $resource

            # Assert: Verify the function did what it's supposed to
            $result.Status | Should -Be 'Compliant'
            $result.Diff | Should -BeNullOrEmpty
        }

        It 'Gets the status and diff when the actual and expected state of a resource are different' {
            # Arrange: Set up any preconditions and inputs
            $resource = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                    ValueName = 'HideFileExt'
                    ValueType = 'DWord'
                    ValueData = @('1')
                    Ensure    = 'Present'
                }
            }

            # Act: Run the function to test
            $result = Compare-DscResourceState $resource

            # Assert: Verify the function did what it's supposed to
            $result.Status | Should -Be 'NonCompliant'
            $result.Diff | Should -Not -BeNullOrEmpty
        }

        It 'Gets the status and diff when the resource is expected to be absent but is present' {
            # Arrange: Set up any preconditions and inputs
            $resource = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                    ValueName = 'HideFileExt'
                    ValueType = 'DWord'
                    ValueData = @('1')
                    Ensure    = 'Absent'
                }
            }

            # Act: Run the function to test
            $result = Compare-DscResourceState $resource

            # Assert: Verify the function did what it's supposed to
            $result.Status | Should -Be 'Unexpected'
            $result.Diff | Should -BeNullOrEmpty
        }

        It 'Gets the status and diff when the resource is expected to be present but is absent' {
            # Arrange: Set up any preconditions and inputs
            $resource = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                    ValueName = 'UnknownValueName'
                    ValueType = 'DWord'
                    ValueData = @('0')
                    Ensure    = 'Present'
                }
            }

            # Act: Run the function to test
            $result = Compare-DscResourceState $resource

            # Assert: Verify the function did what it's supposed to
            $result.Status | Should -Be 'Missing'
            $result.Diff | Should -BeNullOrEmpty
        }

        It 'Gets the status and diff when the resource is expected to be present but getting its state fails' {
            # Arrange: Set up any preconditions and inputs
            $resource = @{
                Name     = 'Registry'
                Property = @{
                    Key       = 'TOTO'
                    ValueName = 'UnknownValueName'
                    ValueType = 'DWord'
                    ValueData = @('0')
                    Ensure    = 'Present'
                }
            }

            # Act: Run the function to test
            $result = Compare-DscResourceState $resource

            # Assert: Verify the function did what it's supposed to
            $result.Status | Should -Be 'Error'
            $result.Diff | Should -BeNullOrEmpty
        }
    }
    
    Context 'Compare-DscResourceState specific cases' {
        It 'Gets the status and diff of MyNodeVersion lts' {
            # Arrange: Set up any preconditions and inputs
            $resource = @{
                Name       = 'MyNodeVersion'
                ModuleName = 'MyResources'
                Property   = @{
                    Version = 'lts'
                    Ensure  = 'Used'
                }
            }

            # Act: Run the function to test
            $result = Compare-DscResourceState $resource

            # Assert: Verify the function did what it's supposed to
            $result.Status | Should -Be 'Compliant'
            $result.Diff | Should -BeNullOrEmpty
        }

        It 'Gets the status and diff of VSComponents' {
            # Arrange: Set up any preconditions and inputs
            $resource = @{
                Name       = 'VSComponents'
                ModuleName = 'Microsoft.VisualStudio.DSC'
                Property   = @{
                    ProductId          = 'Microsoft.VisualStudio.Product.Enterprise'
                    ChannelId          = 'VisualStudio.17.Release'
                    vsConfigFile       = 'C:\Projets\WaC\resources\visual-studio\.vsconfig'
                    includeRecommended = $true
                }
            }

            # Act: Run the function to test
            $result = Compare-DscResourceState $resource

            # Assert: Verify the function did what it's supposed to
            $result.Status | Should -Be 'Compliant'
            $result.Diff | Should -BeNullOrEmpty
        }
    }
}
