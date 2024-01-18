Import-Module Functional

BeforeAll {
    . $PSScriptRoot\Test-IsDeeplyEqual.ps1
}

Describe 'Test-IsDeeplyEqual' {
    Context 'Test-IsDeeplyEqual' {
        It 'should return true when given two empty hashtables' {
            $result = Test-IsDeeplyEqual @{ Key1 = 'Value1'; Key2 = 'Value2' } @{ Key1 = 'Value1'; Key2 = 'Value2' }
            
            $result | Should -Be $true
        }
    }
}
