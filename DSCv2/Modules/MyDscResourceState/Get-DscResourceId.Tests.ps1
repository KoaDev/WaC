Import-Module Functional
Import-Module Pester-ShouldBeDeep

BeforeAll {
    . $PSScriptRoot\Get-DscResourceId.ps1

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
    
        $Result.Identifier | Should -BeDeep $Resource.Property
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
    Context 'Get-DscResourceId' {
        It 'should return a hashtable with the type and identifier' {
            $resource = @{
                Name     = 'Registry'
                Property = @{
                    ValueName = 'ValueName'
                    Key       = 'Key'
                }
            }

            $result = Get-DscResourceId -Resource $resource

            $result | Should -BeDeep @{
                ValueName = 'ValueName'
                Key       = 'Key'
            }
        }
    }
}
