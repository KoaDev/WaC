Import-Module Functional

BeforeAll {
    . $PSScriptRoot\Diff.ps1
}

Describe 'Diff' {
    Context 'Compare-Deep' {
        Context 'Strict' {
            It 'should return true when given two null values' {
                $actual = Compare-Deep $null $null

                $actual | Should -Be $true
            }

            It 'should return false when given one null value' {
                $actual = Compare-Deep $null 'a'

                $actual | Should -Be $false
            }

            It 'should return true when given two empty hashtables' {
                $actual = Compare-Deep @{} @{}

                $actual | Should -Be $true
            }

            It 'should return false when given one empty hashtable' {
                $actual = Compare-Deep @{} @{ a = 'b' }

                $actual | Should -Be $false
            }

            It 'should return true when given two empty arrays' {
                $actual = Compare-Deep @() @()

                $actual | Should -Be $true
            }

            It 'should return false when given one empty array' {
                $actual = Compare-Deep @() @('a')

                $actual | Should -Be $false
            }

            It 'should return true when given two equal hashtables' {
                $actual = Compare-Deep @{ a = 'b' } @{ a = 'b' }

                $actual | Should -Be $true
            }

            It 'should return false when given two hashtables with different keys' {
                $actual = Compare-Deep @{ a = 'b' } @{ c = 'd' }

                $actual | Should -Be $false
            }

            It 'should return false when given two hashtables with different values' {
                $actual = Compare-Deep @{ a = 'b' } @{ a = 'c' }

                $actual | Should -Be $false
            }

            It 'should return true when given two equal arrays' {
                $actual = Compare-Deep @('a', 'b') @('a', 'b')

                $actual | Should -Be $true
            }

            It 'should return false when given two arrays with different lengths' {
                $actual = Compare-Deep @('a', 'b') @('a')

                $actual | Should -Be $false
            }

            It 'should return false when given two arrays with different values' {
                $actual = Compare-Deep @('a', 'b') @('a', 'c')

                $actual | Should -Be $false
            }

            It 'should return true when given two equal enums' {
                $actual = Compare-Deep [System.DayOfWeek]::Monday [System.DayOfWeek]::Monday

                $actual | Should -Be $true
            }

            It 'should return false when given two enums with different values' {
                $actual = Compare-Deep [System.DayOfWeek]::Monday [System.DayOfWeek]::Tuesday

                $actual | Should -Be $false
            }

            It 'should return true when given two equal strings' {
                $actual = Compare-Deep 'a' 'a'

                $actual | Should -Be $true
            }

            It 'should return false when given two strings with different values' {
                $actual = Compare-Deep 'a' 'b'

                $actual | Should -Be $false
            }

            It 'should return true when given two equal value types' {
                $actual = Compare-Deep 1 1

                $actual | Should -Be $true
            }

            It 'should return false when given two value types with different values' {
                $actual = Compare-Deep 1 2

                $actual | Should -Be $false
            }
        }
        
        Context 'Partial' {
            It 'should return true when given two equal hashtables' {
                $actual = Compare-Deep @{ a = 'b' } @{ a = 'b' } -Partial

                $actual | Should -Be $true
            }

            It 'should return true when given a first hashtable with a subset of the keys of the second hashtable' {
                $actual = Compare-Deep @{ a = 'b' } @{ a = 'b'; c = 'd' } -Partial

                $actual | Should -Be $true
            }

            It 'should return false when given a first hashtable with a superset of the keys of the second hashtable' {
                $actual = Compare-Deep @{ a = 'b'; c = 'd' } @{ a = 'b' } -Partial

                $actual | Should -Be $false
            }

            It 'should return true when given two equal arrays' {
                $actual = Compare-Deep @('a', 'b') @('a', 'b') -Partial

                $actual | Should -Be $true
            }

            It 'should return true when given a first array with a subset of the values of the second array' {
                $actual = Compare-Deep @('a', 'b') @('a', 'b', 'c') -Partial

                $actual | Should -Be $true
            }

            It 'should return false when given a first array with a superset of the values of the second array' {
                $actual = Compare-Deep @('a', 'b', 'c') @('a', 'b') -Partial

                $actual | Should -Be $false
            }
        }

        Context 'Verbose' {
            It 'should return false and explain why when given one null value' {
                $actual = Compare-Deep $null 'a' -Verbose 4>&1 |
                    Tee-Object -Variable verboseOutput |
                    Where-Object { $_ -is [bool] }

                $actual | Should -Be $false
                $verboseOutput | ForEach-Object { $_.Message } | Should -Contain 'One object is null and the other is not.'
            }

            It 'should return false and explain why when given two hashtables with different number of keys' {
                $actual = Compare-Deep @{ a = 'b' } @{ a = 'b'; c = 'd' } -Verbose 4>&1 |
                    Tee-Object -Variable verboseOutput |
                    Where-Object { $_ -is [bool] }

                $actual | Should -Be $false
                $verboseOutput | ForEach-Object { $_.Message } | Should -Contain 'Hashtables are different.'
                $verboseOutput | ForEach-Object { $_.Message } | Should -Contain 'Hashtable lengths are different.'
            }

            It 'should return false and explain why when given two hashtables with different keys' {
                $actual = Compare-Deep @{ a = 'b' } @{ c = 'd' } -Verbose 4>&1 |
                    Tee-Object -Variable verboseOutput |
                    Where-Object { $_ -is [bool] }

                $actual | Should -Be $false
                $verboseOutput | ForEach-Object { $_.Message } | Should -Contain 'Hashtables are different.'
                $verboseOutput | ForEach-Object { $_.Message } | Should -Contain "Key 'a' from Hashtable1 does not exist in Hashtable2."
            }

            It 'should return false and explain why when given two hashtables with different values' {
                $actual = Compare-Deep @{ a = 'b' } @{ a = 'c' } -Verbose 4>&1 |
                    Tee-Object -Variable verboseOutput |
                    Where-Object { $_ -is [bool] }

                $actual | Should -Be $false
                $verboseOutput | ForEach-Object { $_.Message } | Should -Contain 'Hashtables are different.'
                $verboseOutput | ForEach-Object { $_.Message } | Should -Contain "Value 'b' for key 'a' in Hashtable1 does not match value 'c' in Hashtable2."
            }
            
            It 'should return false and explain why when given two arrays with different lengths' {
                $actual = Compare-Deep @('a', 'b') @('a') -Verbose 4>&1 |
                    Tee-Object -Variable verboseOutput |
                    Where-Object { $_ -is [bool] }

                $actual | Should -Be $false
                $verboseOutput | ForEach-Object { $_.Message } | Should -Contain 'Arrays are different.'
                $verboseOutput | ForEach-Object { $_.Message } | Should -Contain 'Array lengths are different.'
            }

            It 'should return false and explain why when given two arrays with different values' {
                $actual = Compare-Deep @('a', 'b') @('a', 'c') -Verbose 4>&1 |
                    Tee-Object -Variable verboseOutput |
                    Where-Object { $_ -is [bool] }

                $actual | Should -Be $false
                $verboseOutput | ForEach-Object { $_.Message } | Should -Contain 'Arrays are different.'
                $verboseOutput | ForEach-Object { $_.Message } | Should -Contain "Value 'b' at index 1 in Array1 does not match value 'c' at index 1 in Array2."
            }

            It 'should return false and explain why when given two enums with different values' {
                $actual = Compare-Deep [System.DayOfWeek]::Monday [System.DayOfWeek]::Tuesday -Verbose 4>&1 |
                    Tee-Object -Variable verboseOutput |
                    Where-Object { $_ -is [bool] }

                $actual | Should -Be $false
                $verboseOutput | ForEach-Object { $_.Message } | Should -Contain "Value '[System.DayOfWeek]::Monday' of Object1 does not match value '[System.DayOfWeek]::Tuesday' of Object2."
            }

            It 'should return false and explain why when given two strings with different values' {
                $actual = Compare-Deep 'a' 'b' -Verbose 4>&1 |
                    Tee-Object -Variable verboseOutput |
                    Where-Object { $_ -is [bool] }

                $actual | Should -Be $false
                $verboseOutput | ForEach-Object { $_.Message } | Should -Contain "Value 'a' of Object1 does not match value 'b' of Object2."
            }

            It 'should return false and explain why when given two value types with different values' {
                $actual = Compare-Deep 1 2 -Verbose 4>&1 |
                    Tee-Object -Variable verboseOutput |
                    Where-Object { $_ -is [bool] }

                $actual | Should -Be $false
                $verboseOutput | ForEach-Object { $_.Message } | Should -Contain "Value '1' of Object1 does not match value '2' of Object2."
            }
        }
    }
}