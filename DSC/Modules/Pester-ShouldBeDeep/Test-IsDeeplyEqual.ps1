function Convert-HashtableKeysToStrings
{
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $InputHashtable
    )

    process
    {
        if ($yourVariable -isnot [hashtable])
        {
            return $InputHashtable
        }

        $newHashtable = @{}
        foreach ($key in $InputHashtable.Keys)
        {
            $newKey = $key -is [string] ? $key : $key.ToString()
            $newHashtable[$newKey] = $InputHashtable[$key]
        }

        return $newHashtable
    }
}

function Test-IsDeeplyEqual ($ActualValue, $ExpectedValue, [switch] $Negate, [string] $Because)
{
    return Test-IsDeeplyEqualInternal $ActualValue $ExpectedValue -Negate:$Negate -Because:$Because
}

function Test-IsDeeplyEqualPartial ($ActualValue, $ExpectedValue, [switch] $Negate, [string] $Because)
{
    return Test-IsDeeplyEqualInternal $ActualValue $ExpectedValue -Negate:$Negate -Because:$Because -Partial
}

function Test-IsDeeplyEqualInternal
{
    param (
        $ActualValue,
        $ExpectedValue,
        [switch] $Negate,
        [string] $Because,
        [switch] $Partial
    )

    if ($ExpectedValue -is [hashtable] -and $ActualValue -is [psobject[]] -and $ActualValue.Count -eq 1 -and $ActualValue[0] -is [hashtable])
    {
        $ActualValue = $ActualValue[0]
    }

    $verboseOutput = @()
    [bool] $succeeded = Compare-Deep $ExpectedValue $ActualValue -Partial:$Partial -Verbose 4>&1 |
        Tee-Object -Variable verboseOutput |
        Where-Object { $_ -is [bool] }

    if ($Negate)
    {
        $succeeded = -not $succeeded 
    }

    $failureMessage = $null
    if (-not $succeeded)
    {
        $actualString = $ActualValue | Convert-HashtableKeysToStrings | ConvertTo-Json -EnumsAsStrings -Depth 100
        $expectedString = $ExpectedValue | Convert-HashtableKeysToStrings | ConvertTo-Json -EnumsAsStrings -Depth 100

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
Expected ($($ExpectedValue.GetType())):
$expectedString
Actual ($($ActualValue.GetType())):
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
