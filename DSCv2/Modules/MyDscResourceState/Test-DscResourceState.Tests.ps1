Import-Module Functional
Import-Module Pester-ShouldBeDeep

BeforeAll {
    Get-ChildItem -Path "$PSScriptRoot\*.ps1" -Exclude '*.Tests.ps1' | ForEach-Object { . $_.FullName }

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

    function Assert-TypeAndIdentifier
    {
        param (
            [Parameter(Mandatory = $true)]
            $Resource,
    
            [Parameter(Mandatory = $true)]
            $Result
        )
    
        $Result.Type | Should -Be $Resource.Name
        $Result.Identifier | Should -BeDeep $Resource.Property
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
}
