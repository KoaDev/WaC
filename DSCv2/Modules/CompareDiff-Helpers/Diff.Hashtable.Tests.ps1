Import-Module Functional

BeforeAll {
    . $PSScriptRoot\Diff.ps1
}

Describe 'Diff' {
    Context 'Get-HashtableDiff' {
        It 'should return an empty result when given two empty hashtables' {
            $actual = Get-HashtableDiff -Hashtable1 @{} -Hashtable2 @{}

            $actual.Added | Should -BeNullOrEmpty
            $actual.Removed | Should -BeNullOrEmpty
            $actual.Modified | Should -BeNullOrEmpty
        }

        It 'should return an empty result when given two hashtables with the same content' {
            $actual = Get-HashtableDiff -Hashtable1 @{ a = 'a'; b = 'b'; c = 'c' } -Hashtable2 @{ a = 'a'; b = 'b'; c = 'c' }

            $actual.Added | Should -BeNullOrEmpty
            $actual.Removed | Should -BeNullOrEmpty
            $actual.Modified | Should -BeNullOrEmpty
        }

        It 'should return the added keys when given two hashtables with different content' {
            $actual = Get-HashtableDiff -Hashtable1 @{ a = 'a'; b = 'b'; c = 'c' } -Hashtable2 @{ a = 'a'; b = 'b'; c = 'c'; d = 'd'; e = 'e' }

            $actual.Added | Sort-Object | Should -Be @('d', 'e')
            $actual.Removed | Should -BeNullOrEmpty
            $actual.Modified | Should -BeNullOrEmpty
        }

        It 'should return the removed keys when given two hashtables with different content' {
            $actual = Get-HashtableDiff -Hashtable1 @{ a = 'a'; b = 'b'; c = 'c'; d = 'd'; e = 'e' } -Hashtable2 @{ a = 'a'; b = 'b'; c = 'c' }

            $actual.Added | Should -BeNullOrEmpty
            $actual.Removed | Sort-Object | Should -Be @('d', 'e')
            $actual.Modified | Should -BeNullOrEmpty
        }

        It 'should return the modified keys when given two hashtables with different content' {
            $actual = Get-HashtableDiff -Hashtable1 @{ a = 'a'; b = 'b'; c = 'c' } -Hashtable2 @{ a = 'a'; b = 'b'; c = 'd' }

            $actual.Added | Should -BeNullOrEmpty
            $actual.Removed | Should -BeNullOrEmpty
            $actual.Modified.Keys | Should -Be @('c')
        }

        It 'should return the added, removed, and modified keys when given two hashtables with different content' {
            $actual = Get-HashtableDiff -Hashtable1 @{ a = 'a'; b = 'b'; c = 'c'; d = 'd'; e = 'e' } -Hashtable2 @{ a = 'a'; b = 'b'; c = 'd'; f = 'f'; g = 'g' }

            $actual.Added | Sort-Object | Should -Be @('f', 'g')
            $actual.Removed | Sort-Object | Should -Be @('d', 'e')
            $actual.Modified.Keys | Should -Be @('c')
        }

        It 'should return the modified keys whith their before and after values for scalar values' {
            $actual = Get-HashtableDiff -Hashtable1 @{ a = 'a'; b = 'b'; c = 'c' } -Hashtable2 @{ a = 'a'; b = 'b'; c = 'd' }

            $actual.Added | Should -BeNullOrEmpty
            $actual.Removed | Should -BeNullOrEmpty
            $actual.Modified.c.Before | Should -Be 'c'
            $actual.Modified.c.After | Should -Be 'd'
        }

        It 'should return the modified keys with the result of Get-HashtableDiff for hashtable values' {
            $actual = Get-HashtableDiff -Hashtable1 @{ a = @{ a = 'a'; b = 'b'; c = 'c' } } -Hashtable2 @{ a = @{ a = 'a'; b = 'b'; c = 'd' } }

            $actual.Added | Should -BeNullOrEmpty
            $actual.Removed | Should -BeNullOrEmpty
            $actual.Modified.a.Modified.c.Before | Should -Be 'c'
            $actual.Modified.a.Modified.c.After | Should -Be 'd'
        }
    }
}
