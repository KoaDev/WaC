Import-Module Functional

BeforeAll {
    . $PSScriptRoot\Diff.ps1
}

Describe 'Diff' {
    Context 'Get-ArrayDiff' {
        It 'should return an empty result when given two empty arrays' {
            $actual = Get-ArrayDiff @() @()

            $actual.Added | Should -BeNullOrEmpty
            $actual.Removed | Should -BeNullOrEmpty
        }

        It 'should return an empty result when given two arrays with the same objects' {
            $actual = Get-ArrayDiff @('a', 'b', 'c') @('a', 'b', 'c')

            $actual.Added | Should -BeNullOrEmpty
            $actual.Removed | Should -BeNullOrEmpty
        }

        It 'should return the added objects at the end when given two arrays with different objects' {
            $actual = Get-ArrayDiff @('a', 'b', 'c') @('a', 'b', 'c', 'd', 'e')

            $actual.Added | Should -Be @('d', 'e')
            $actual.Removed | Should -BeNullOrEmpty
        }

        It 'should return the added objects at the beginning when given two arrays with different objects' {
            $actual = Get-ArrayDiff @('a', 'b', 'c') @('d', 'e', 'a', 'b', 'c')

            $actual.Added | Should -Be @('d', 'e')
            $actual.Removed | Should -BeNullOrEmpty
        }

        It 'should return the added objects in the middle when given two arrays with different objects' {
            $actual = Get-ArrayDiff @('a', 'b', 'c') @('a', 'd', 'e', 'b', 'c')

            $actual.Added | Should -Be @('d', 'e')
            $actual.Removed | Should -BeNullOrEmpty
        }

        It 'should return the added non-sequential objects when given two arrays with different objects' {
            $actual = Get-ArrayDiff @('a', 'b', 'c') @('a', 'd', 'b', 'e', 'c')

            $actual.Added | Should -Be @('d', 'e')
            $actual.Removed | Should -BeNullOrEmpty
        }

        It 'should return the removed objects at the end when given two arrays with different objects' {
            $actual = Get-ArrayDiff @('a', 'b', 'c', 'd', 'e') @('a', 'b', 'c')

            $actual.Added | Should -BeNullOrEmpty
            $actual.Removed | Should -Be @('d', 'e')
        }

        It 'should return the removed objects at the beginning when given two arrays with different objects' {
            $actual = Get-ArrayDiff @('d', 'e', 'a', 'b', 'c') @('a', 'b', 'c')

            $actual.Added | Should -BeNullOrEmpty
            $actual.Removed | Should -Be @('d', 'e')
        }

        It 'should return the removed objects in the middle when given two arrays with different objects' {
            $actual = Get-ArrayDiff @('a', 'd', 'e', 'b', 'c') @('a', 'b', 'c')

            $actual.Added | Should -BeNullOrEmpty
            $actual.Removed | Should -Be @('d', 'e')
        }

        It 'should return the removed non-sequential objects when given two arrays with different objects' {
            $actual = Get-ArrayDiff @('a', 'd', 'b', 'e', 'c') @('a', 'b', 'c')

            $actual.Added | Should -BeNullOrEmpty
            $actual.Removed | Should -Be @('d', 'e')
        }

        It 'should return the added and removed objects when given two arrays with different objects' {
            $actual = Get-ArrayDiff @('a', 'b', 'c', 'd', 'e') @('f', 'b', 'g', 'd', 'h')

            $actual.Added | Should -Be @('f', 'g', 'h')
            $actual.Removed | Should -Be @('a', 'c', 'e')
        }
    }
}
