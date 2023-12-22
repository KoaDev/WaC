#Requires -Module Pester

. $PSScriptRoot\Compare.ps1

function Convert-HashtableKeysToStrings
{
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$InputHashtable
    )

    process
    {
        $newHashtable = @{}
        foreach ($key in $InputHashtable.Keys)
        {
            $newKey = $key -is [string] ? $key : $key.ToString()
            $newHashtable[$newKey] = $InputHashtable[$key]
        }

        return $newHashtable
    }
}

function Should-BeDeep ($ActualValue, $ExpectedValue, [switch] $Negate, [string] $Because)
{
    $verboseOutput = @()
    [bool] $succeeded = Compare-Deep $ExpectedValue $ActualValue -Verbose 4>&1 |
        Tee-Object -Variable verboseOutput |
        Where-Object { $_ -is [bool] }

    if ($Negate)
    {
        $succeeded = -not $succeeded 
    }

    $failureMessage = $null
    if (-not $succeeded)
    {
        $actualString = $ActualValue | Convert-HashtableKeysToStrings | ConvertTo-Json -Depth 100
        $expectedString = $ExpectedValue | Convert-HashtableKeysToStrings | ConvertTo-Json -Depth 100

        if ($Negate)
        {
            $failureMessage = @"
Expected objects to not be equal$(if($Because) { " because $Because"}), but got the same value.
value:
$expectedString
"@
        }
        else
        {
            $failureMessage = @"
Expected objects to be equal$(if($Because) { " because $Because"}).
Expected:
$expectedString
Actual:
$actualString
Detail:
$($verboseOutput -join "`n")
"@
        }
    }

    return [pscustomobject]@{
        Succeeded      = $succeeded
        FailureMessage = $failureMessage
    }
}

Add-ShouldOperator -Name BeDeep `
    -InternalName 'Should-BeDeep' `
    -Test ${function:Should-BeDeep}
