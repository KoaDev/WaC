Import-Module Functional
Import-Module Pester-ShouldBeDeep

BeforeAll {
    . $PSScriptRoot\Set-DscResourceState.ps1

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
        It 'Returns InDesiredState = True for an existing resource' {
            # Arrange: Set up any preconditions and inputs
            $resource = @{
                Name       = 'WinGetPackage'
                ModuleName = 'Microsoft.WinGet.DSC'
                Property   = @{
                    Id = 'Microsoft.PowerShell'
                }
            }

            # Act: Run the function to test
            $result = Set-DscResourceState $resource

            # Assert: Verify the function did what it's supposed to
        }
    }
}
