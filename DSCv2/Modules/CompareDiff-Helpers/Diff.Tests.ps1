Import-Module Functional

BeforeAll {
    . $PSScriptRoot\Diff.ps1
}

Describe 'Diff' {
    Context 'Test-IsDiffResult' {
        It 'should return false when given a null value' {
            $actual = Test-IsDiffResult $null

            $actual | Should -Be $false
        }

        It 'should return false when given a non-null value' {
            $actual = Test-IsDiffResult 'a'

            $actual | Should -Be $false
        }

        It 'should return true when given a hashtable with added, removed, and modified keys' {
            $actual = Test-IsDiffResult @{
                Added    = @()
                Removed  = @()
                Modified = @{}
            }

            $actual | Should -Be $true
        }

        It 'should return true when given a hashtable with added keys' {
            $actual = Test-IsDiffResult @{
                Added = @()
            }

            $actual | Should -Be $true
        }

        It 'should return true when given a hashtable with removed keys' {
            $actual = Test-IsDiffResult @{
                Removed = @()
            }

            $actual | Should -Be $true
        }

        It 'should return true when given a hashtable with modified keys' {
            $actual = Test-IsDiffResult @{
                Modified = @{}
            }

            $actual | Should -Be $true
        }

        It 'should return false when given a hashtable with added, removed, and modified keys and a non-allowed key' {
            $actual = Test-IsDiffResult @{
                Added    = @()
                Removed  = @()
                Modified = @{}
                d        = 'f'
            }

            $actual | Should -Be $false
        }
    }

    Context 'Get-Diff' {
        It 'should return an empty result when given two null values' {
            $actual = Get-Diff $null $null

            $actual | Should -BeNullOrEmpty
        }

        It 'should return the before and after values when given a null and non-null value' {
            $actual = Get-Diff $null 'a'

            $actual.Before | Should -Be $null
            $actual.After | Should -Be 'a'
        }

        It 'should return the before and after values when given a non-null and null value' {
            $actual = Get-Diff 'a' $null

            $actual.Before | Should -Be 'a'
            $actual.After | Should -Be $null
        }

        It 'should return the before and after values when given value types of different types' {
            $actual = Get-Diff 'a' 1

            $actual.Before | Should -Be 'a'
            $actual.After | Should -Be 1
        }

        It 'should return the before and after values when given object types of different types' {
            $actual = Get-Diff 'a' @(1, 2)

            $actual.Before | Should -Be 'a'
            $actual.After | Should -Be '[1,2]'
        }

        It 'should return an empty result when given two identical enum values' {
            $actual = Get-Diff ([System.DayOfWeek]::Monday) ([System.DayOfWeek]::Monday)

            $actual | Should -BeNullOrEmpty
        }

        It 'should return the before and after values for different enum values' {
            $actual = Get-Diff ([System.DayOfWeek]::Monday) ([System.DayOfWeek]::Tuesday)

            $actual.Before | Should -Be 'Monday'
            $actual.After | Should -Be 'Tuesday'
        }

        It 'should return an empty result when given two identical string values' {
            $actual = Get-Diff 'a' 'a'

            $actual | Should -BeNullOrEmpty
        }

        It 'should return the before and after values for different string values' {
            $actual = Get-Diff 'a' 'b'

            $actual.Before | Should -Be 'a'
            $actual.After | Should -Be 'b'
        }

        It 'should return an empty result when given two identical value type values' {
            $actual = Get-Diff 1 1

            $actual | Should -BeNullOrEmpty
        }

        It 'should return the before and after values for different value type values' {
            $actual = Get-Diff 1 2

            $actual.Before | Should -Be 1
            $actual.After | Should -Be 2
        }

        It 'should return an empty result when given two identical array values' {
            $actual = Get-Diff @(1, 2) @(1, 2)

            $actual | Should -BeNullOrEmpty
        }

        It 'should return the before and after values for different array values' {
            $actual = Get-Diff @(1, 2) @(1, 2, 3)

            $actual.Before | Should -Be '[1,2]'
            $actual.After | Should -Be '[1,2,3]'
        }
    }
}
