Import-Module Functional
Import-Module Pester-ShouldBeDeep

BeforeAll {
    . $PSScriptRoot\Select-DscResourceProperties.ps1
}

Describe 'MyDscResourceState' {
    Context 'Select-DscResourceIdProperties' {
        It 'should return a hashtable with the type and identifier' {
            $resource = @{
                Name     = 'Registry'
                Property = @{
                    ValueName = 'ValueName'
                    Key       = 'Key'
                }
            }

            $result = Select-DscResourceIdProperties -Resource $resource

            $result | Should -BeDeeplyEqualPartial @{
                ValueName = 'ValueName'
                Key       = 'Key'
            }
        }

        It 'should throw an error when the resource name is unknown' {
            $resource = @{
                Name     = 'Unknown'
                Property = @{
                    ValueName = 'ValueName'
                    Key       = 'Key'
                }
            }

            { Select-DscResourceIdProperties -Resource $resource } | Should -Throw "The resource 'Unknown' is not supported."
        }
    }
}
