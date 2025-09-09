. $PSScriptRoot\Compare.ps1
. $PSScriptRoot\Diff.ps1

Export-ModuleMember `
    -Function Compare-Deep, Get-Diff
