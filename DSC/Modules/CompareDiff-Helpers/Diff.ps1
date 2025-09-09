. $PSScriptRoot\Compare.ps1
. $PSScriptRoot\Helpers.ps1

function Get-Diff
{
    [CmdletBinding()]
    param (
        $ExpectedObject,
        $ActualObject
    )

    if ($ExpectedObject -is [collections.IDictionary] -and $ActualObject -is [collections.IDictionary])
    {
        if (Compare-Deep $ExpectedObject $ActualObject -Verbose:($PSBoundParameters['Verbose'] -eq $true))
        {
            return @{}
        }
        else
        {
            return Get-HashtableDiff $ExpectedObject $ActualObject
        }
    }

    if ($ExpectedObject -is [array] -and $ActualObject -is [array])
    {
        if (Compare-Array $ExpectedObject $ActualObject -Verbose:($PSBoundParameters['Verbose'] -eq $true))
        {
            return @{}
        }
        else
        {
            return Get-ExpectedActual $ExpectedObject $ActualObject
        }
    }

    if ((Test-IsValueType $ExpectedObject) -and (Test-IsValueType $ActualObject))
    {
        if ($ExpectedObject -eq $ActualObject)
        {
            return @{}
        }
        else
        {
            return Get-ExpectedActual $ExpectedObject $ActualObject
        }
    }

    $result = Get-ExpectedActual $ExpectedObject $ActualObject
    $result.Error = 'Unable to compare objects of type ' + $ExpectedObject.GetType().FullName + ' and ' + $ActualObject.GetType().FullName + '.'
    return $result
}

function Get-HashtableDiff
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $ExpectedHashtable,

        [Parameter(Mandatory = $true)]
        $ActualHashtable
    )

    $result = @{}

    foreach ($key in $ExpectedHashtable.Keys)
    {
        if (-not $ActualHashtable.ContainsKey($key))
        {
            $result.Removed = $result.Removed ?? @{}
            $result.Removed[$key] = $ExpectedHashtable[$key]
        }
        elseif (-not (Compare-Deep $ExpectedHashtable[$key] $ActualHashtable[$key] -Verbose:($PSBoundParameters['Verbose'] -eq $true)))
        {
            $result.Modified = $result.Modified ?? @{}
            $result.Modified[$key] = Get-Diff $ExpectedHashtable[$key] $ActualHashtable[$key]
        }
    }

    foreach ($key in $ActualHashtable.Keys)
    {
        if (-not $ExpectedHashtable.ContainsKey($key))
        {
            $result.Added = $result.Added ?? @{}
            $result.Added[$key] = $ActualHashtable[$key]
        }
    }

    return $result
}

function Get-ArrayDiff
{
    [CmdletBinding()]
    param (
        [array]$ExpectedArray,
        [array]$ActualArray
    )

    $result = @{}

    $lastMatchI2 = -1

    for ($i1 = 0; $i1 -lt $ExpectedArray.Count; $i1++)
    {
        $item1 = $ExpectedArray[$i1]
        $hasMatched = $false

        for ($i2 = $lastMatchI2 + 1; $i2 -lt $ActualArray.Count; $i2++)
        {
            $item2 = $ActualArray[$i2]

            if (Compare-Deep $item1 $item2 -Verbose:($PSBoundParameters['Verbose'] -eq $true))
            {
                $hasMatched = $true

                for ($j = $lastMatchI2 + 1; $j -lt $i2; $j++)
                {
                    $result.Added = $result.Added ?? @()
                    $result.Added += Get-ObjectString $ActualArray[$j]
                }
                $lastMatchI2 = $i2

                break
            }
        }

        if (-not $hasMatched)
        {
            $result.Removed = $result.Removed ?? @()
            $result.Removed += Get-ObjectString $item1
        }
    }

    for ($i = $lastMatchI2 + 1; $i -lt $ActualArray.Count; $i++)
    {
        $result.Added = $result.Added ?? @()
        $result.Added += Get-ObjectString $ActualArray[$i]
    }

    return $result
}
