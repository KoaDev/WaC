#Requires -Module Pester

. $PSScriptRoot\Test-IsDeeplyEqual.ps1

Add-ShouldOperator -Name BeDeeplyEqual `
    -InternalName 'Should-BeDeeplyEqual' `
    -Test ${function:Test-IsDeeplyEqual} `
    -SupportsArrayInput

Add-ShouldOperator -Name BeDeeplyEqualPartial `
    -InternalName 'Should-BeDeeplyEqualPartial' `
    -Test ${function:Test-IsDeeplyEqualPartial} `
    -SupportsArrayInput
