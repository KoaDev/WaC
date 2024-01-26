Import-Module Functional
Import-Module Pester-ShouldBeDeep

BeforeAll {
    . $PSScriptRoot\Test-DscResourceState.ps1

    function Assert-Type
    {
        param (
            [Parameter(Mandatory = $true)]
            $Resource,
    
            [Parameter(Mandatory = $true)]
            $Result
        )
    
        $Result.Type | Should -Be $Resource.Name
    }

    function Assert-Identifier
    {
        param (
            [Parameter(Mandatory = $true)]
            $Resource,
    
            [Parameter(Mandatory = $true)]
            $Result
        )
    
        $Result.Identifier | Should -BeDeeplyEqualPartial $Resource.Property
    }

    function Assert-TypeAndIdentifier
    {
        param (
            [Parameter(Mandatory = $true)]
            $Resource,
    
            [Parameter(Mandatory = $true)]
            $Result
        )
    
        Assert-Type -Resource $Resource -Result $Result
        Assert-Identifier -Resource $Resource -Result $Result
    }
}

Describe 'MyDscResourceState' {
    Context 'Test-DscResourceState' {
        It 'Returns InDesiredState = False for a non-existing resource' {
            # Arrange: Set up any preconditions and inputs
            $resource = @{
                Name     = 'Registry'
                Property = @{
                    ValueName = 'NonExistingValue'
                    Key       = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion'
                }
            }

            # Act: Run the function to test
            $result = Test-DscResourceState $resource

            # Assert: Verify the function did what it's supposed to
            Assert-TypeAndIdentifier -Resource $resource -Result $result
            $result.InDesiredState | Should -BeFalse
        }

        It 'Returns InDesiredState = True for an existing resource' {
            # Arrange: Set up any preconditions and inputs
            $resource = @{
                Name     = 'Registry'
                Property = @{
                    ValueName = 'ProgramFilesDir'
                    Key       = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion'
                }
            }

            # Act: Run the function to test
            $result = Test-DscResourceState $resource

            # Assert: Verify the function did what it's supposed to
            Assert-TypeAndIdentifier -Resource $resource -Result $result
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context 'Test-DscResourceState specific cases' {
        It 'Returns the desired state for VSComponents' {
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
            # Assert: Verify the function did what it's supposed to
            { Test-DscResourceState $resource } | Should -Not -Throw }
    }
}
